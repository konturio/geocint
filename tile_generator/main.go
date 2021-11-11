package main

import (
	"bytes"
	"context"
	"crypto/md5"
	"database/sql"
	"flag"
	"fmt"
	"github.com/jackc/pgx/v4"
	"github.com/jackc/pgx/v4/pgxpool"
	_ "github.com/mattn/go-sqlite3"
	"io"
	"io/ioutil"
	"log"
	"math"
	"os"
	"path"
	"strconv"
	"sync"
	"time"
)

// example usage: tile-generator --parallel-limit 10 --min-zoom 7 --max-zoom 7 --sql 'select basemap(:z, :x, :y)' --db-config 'host=localhost dbname=gis'
var maxParallel = flag.Int("j", 32, "parallel limit")
var minZoom = flag.Int("min-zoom", 0, "min zoom")
var maxZoom = flag.Int("max-zoom", 8, "max zoom")
var sqlQueryFilepath = flag.String("sql-query-filepath", "", "sql query file path")
var dbConfig = flag.String("db-config", "", "db config")
var outputMbtiles = flag.String("output-mbtiles", "", "output mbtiles path")
var outputPath = flag.String("output-path", "", "output path")

type TileZxy struct {
	z, x, y    int
	parentHash [16]byte
}

func mbtilesOpen(path string) (*sql.DB, error) {
	db, err := sql.Open("sqlite3", "file:"+path+"?cache=shared&_synchronous=0&_journal_mode=DELETE&_locking_mode=EXCLUSIVE")
	if err != nil {
		return nil, err
	}

	_, err = db.Exec("create table map (zoom_level integer, tile_column integer, tile_row integer, tile_id text)")
	if err != nil {
		return nil, err
	}

	_, err = db.Exec("create table images (tile_data blob, tile_id text)")
	if err != nil {
		return nil, err
	}

	_, err = db.Exec("create unique index map_index on map (zoom_level, tile_column, tile_row)")
	if err != nil {
		return nil, err
	}

	_, err = db.Exec("create unique index images_id on images (tile_id)")
	if err != nil {
		return nil, err
	}

	_, err = db.Exec(`create view tiles as
    	select
        	map.zoom_level as zoom_level,
        	map.tile_column as tile_column,
        	map.tile_row as tile_row,
        	images.tile_data as tile_data
    	from map
    	join images on images.tile_id = map.tile_id`)
	if err != nil {
		return nil, err
	}

	return db, err
}

func mbtilesWriteTile(db *sql.DB, z int, x int, y int, tile []byte, hash string) error {
	insertMapStmt, err := db.Prepare("insert into map (zoom_level, tile_column, tile_row, tile_id) values (?, ?, ?, ?)")
	if err != nil {
		return err
	}
	defer insertMapStmt.Close()

	insertImageStmt, err := db.Prepare("insert or ignore into images (tile_data, tile_id) values (?, ?)")
	if err != nil {
		return err
	}
	defer insertMapStmt.Close()

	_, err = insertMapStmt.Exec(z, x, (1<<z)-1-y, hash)
	if err != nil {
		return err
	}

	_, err = insertImageStmt.Exec(hash, tile)
	if err != nil {
		return err
	}

	return err
}

func fsWriteTile(outputPath string, z int, x int, y int, tile []byte) error {
	dir := path.Join(outputPath, fmt.Sprintf("%d/%d", z, x))
	filePath := path.Join(outputPath, fmt.Sprintf("%d/%d/%d.mvt", z, x, y))

	err := os.MkdirAll(dir, 0777)
	if err != nil {
		return err
	}

	out, err := os.Create(filePath)
	if err != nil {
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, bytes.NewReader(tile))
	if err != nil {
		return err
	}

	return err
}

var globalDb *pgxpool.Pool = nil

func dbConnect(tileSql string) (*pgxpool.Pool, error) {
	if globalDb == nil {
		var err error
		var config *pgxpool.Config
		config, err = pgxpool.ParseConfig(*dbConfig)
		if err != nil {
			log.Fatal(err)
		}

		// Read and parse connection lifetime
		dbPoolMaxLifeTime, _ := time.ParseDuration("24h")
		config.MaxConnLifetime = dbPoolMaxLifeTime

		config.MaxConns = int32(*maxParallel)

		config.AfterConnect = func(ctx context.Context, c *pgx.Conn) error {
			_, err := c.Exec(ctx, "set jit = off")
			if err != nil {
				return err
			}
			_, err = c.Exec(ctx, "set max_parallel_workers_per_gather = 0")
			if err != nil {
				return err
			}
			_, err = c.Prepare(ctx, "query_tile", tileSql)
			return err
		}

		globalDb, err = pgxpool.ConnectConfig(context.Background(), config)
		if err != nil {
			log.Fatal(err)
		}
		dbName := config.ConnConfig.Config.Database
		dbUser := config.ConnConfig.Config.User
		dbHost := config.ConnConfig.Config.Host
		log.Printf("Connected as '%s' to '%s' @ '%s'", dbUser, dbName, dbHost)

		return globalDb, err
	}
	return globalDb, nil
}

type ResultTile struct {
	z             int
	x             int
	y             int
	tile          []byte
	hash          [16]byte
	executionTime time.Duration
}

func queryTile(db *pgxpool.Conn, zxy TileZxy) (ResultTile, error) {
	tileQueryStartTime := time.Now()
	row := db.QueryRow(context.Background(), "query_tile", strconv.Itoa(zxy.z), strconv.Itoa(zxy.x), strconv.Itoa(zxy.y))
	var tile []byte
	err := row.Scan(&tile)
	tileQueryElapsedTime := time.Since(tileQueryStartTime)

	return ResultTile{zxy.z, zxy.x, zxy.y, tile, md5.Sum(tile), tileQueryElapsedTime}, err
}

func worker(pool *pgxpool.Pool, jobs chan TileZxy, results chan<- ResultTile, wg *sync.WaitGroup) {
	for zxy := range jobs {
		c, err := pool.Acquire(context.Background())
		if err != nil {
			log.Fatal(err)
		}

		if zxy.z <= 6 {
			result, err := queryTile(c, zxy)
			if err != nil {
				log.Fatalf("z: %d x: %d y: %d error: %s", zxy.z, zxy.x, zxy.y, err.Error())
			}
			results <- result

			zxy := zxy
			wg.Add(4)
			if zxy.z < *maxZoom {
				go func() {
					jobs <- TileZxy{zxy.z + 1, zxy.x * 2, zxy.y * 2, result.hash}
					jobs <- TileZxy{zxy.z + 1, zxy.x*2 + 1, zxy.y * 2, result.hash}
					jobs <- TileZxy{zxy.z + 1, zxy.x * 2, zxy.y*2 + 1, result.hash}
					jobs <- TileZxy{zxy.z + 1, zxy.x*2 + 1, zxy.y*2 + 1, result.hash}
				}()
			}
		} else {
			var stack []TileZxy
			stack = append(stack, zxy)
			for len(stack) > 0 {
				zxy := stack[len(stack)-1]
				stack = stack[:len(stack)-1]

				result, err := queryTile(c, zxy)
				if err != nil {
					log.Fatalf("z: %d x: %d y: %d error: %s", zxy.z, zxy.x, zxy.y, err.Error())
				}
				results <- result

				if zxy.z < *maxZoom && (bytes.Compare(zxy.parentHash[:], result.hash[:]) != 0 || zxy.z < 10) {
					stack = append(stack, TileZxy{zxy.z + 1, zxy.x * 2, zxy.y * 2, result.hash})
					stack = append(stack, TileZxy{zxy.z + 1, zxy.x*2 + 1, zxy.y * 2, result.hash})
					stack = append(stack, TileZxy{zxy.z + 1, zxy.x * 2, zxy.y*2 + 1, result.hash})
					stack = append(stack, TileZxy{zxy.z + 1, zxy.x*2 + 1, zxy.y*2 + 1, result.hash})
				}
			}
		}

		c.Release()
		wg.Done()
	}
}

func main() {
	flag.Parse()

	var mbtiles *sql.DB
	var err error

	if len(*outputMbtiles) > 0 {
		mbtiles, err = mbtilesOpen(*outputMbtiles)
		if err != nil {
			log.Fatal(err)
		}
		defer mbtiles.Close()
	}

	tileSql, err := ioutil.ReadFile(*sqlQueryFilepath)
	if err != nil {
		log.Fatal(err)
	}

	db, err := dbConnect(string(tileSql))
	if err != nil {
		log.Fatal(err)
		return
	}

	jobs := make(chan TileZxy, *maxParallel)
	results := make(chan ResultTile)
	readDone := make(chan bool)
	wg := &sync.WaitGroup{}

	for i := 0; i < *maxParallel; i++ {
		go worker(db, jobs, results, wg)
	}

	z := *minZoom
	for x := 0; x < int(math.Pow(float64(2), float64(z))); x++ {
		for y := 0; y < int(math.Pow(float64(2), float64(z))); y++ {
			wg.Add(1)
			zxy := TileZxy{z, x, y, [16]byte{0}}
			go func() {
				jobs <- zxy
			}()
		}
	}

	go func() {
		wg.Wait()
		readDone <- true
	}()

loop:
	for {
		select {
		case res := <-results:
			log.Printf("z: %d, x: %d, y: %d, bytes: %d, execution time: %s", res.z, res.x, res.y, len(res.tile), res.executionTime)
			if len(*outputPath) > 0 {
				err = fsWriteTile(*outputPath, res.z, res.x, res.y, res.tile)
			}
			if mbtiles != nil {
				err = mbtilesWriteTile(mbtiles, res.z, res.x, res.y, res.tile, fmt.Sprintf("%x", res.hash))
			}

			if err != nil {
				log.Fatalf("z: %d x: %d y: %d error: %s", res.z, res.x, res.y, err.Error())
			}
		case <-readDone:
			close(jobs)
			break loop
		}
	}
}
