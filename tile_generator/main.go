package main

import (
	"bytes"
	"context"
	"database/sql"
	"flag"
	"fmt"
	// "github.com/gen0cide/waiter"
	"crypto/md5"
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

	_, err = db.Exec("create table tiles (zoom_level integer, tile_column integer, tile_row integer, tile_data blob)")
	if err != nil {
		return nil, err
	}

	return db, err
}

func mbtilesWriteTile(db *sql.DB, z int, x int, y int, tile []byte) error {
	stmt, err := db.Prepare("insert into tiles (zoom_level, tile_column, tile_row, tile_data) values (?, ?, ?, ?)")
	if err != nil {
		return err
	}
	defer stmt.Close()

	_, err = stmt.Exec(z, x, (1<<z)-1-y, tile)
	return err
}

func mbtilesCreateIndexes(db *sql.DB) error {
	_, err := db.Exec("create unique index tile_index on tiles (zoom_level, tile_column, tile_row)")
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
	executionTime time.Duration
}

func queryTile(db *pgxpool.Conn, zxy TileZxy) (ResultTile, error) {
	tileQueryStartTime := time.Now()
	row := db.QueryRow(context.Background(), "query_tile", strconv.Itoa(zxy.z), strconv.Itoa(zxy.x), strconv.Itoa(zxy.y))
	var tile []byte
	err := row.Scan(&tile)
	tileQueryElapsedTime := time.Since(tileQueryStartTime)

	return ResultTile{zxy.z, zxy.x, zxy.y, tile, tileQueryElapsedTime}, err
}

func worker(pool *pgxpool.Pool, jobs chan TileZxy, results chan<- ResultTile, wg *sync.WaitGroup) {
	for zxy := range jobs {
		// result, err := queryTile(db, zxy)
		// if err != nil {
		// 	log.Fatalln("z: %d x: %d y: %d error: %s", zxy.z, zxy.x, zxy.y, err.Error())
		// }

		// results <- result

		// if zxy.z < *maxZoom && (len(result.tile) != 0 || zxy.z < 10) {
		// 	zxy := zxy
		// 	wg.Add(4)
		// 	go func() {
		// 		jobs <- TileZxy{zxy.z + 1, zxy.x * 2, zxy.y * 2}
		// 		jobs <- TileZxy{zxy.z + 1, zxy.x*2 + 1, zxy.y * 2}
		// 		jobs <- TileZxy{zxy.z + 1, zxy.x * 2, zxy.y*2 + 1}
		// 		jobs <- TileZxy{zxy.z + 1, zxy.x*2 + 1, zxy.y*2 + 1}
		// 	}()
		// }

		// wg.Done()
		// if zxy.z > *maxZoom {
		// 	wg.Done()
		// 	continue
		// }

		c, err := pool.Acquire(context.Background())
		if err != nil {
			log.Fatal(err)
		}

		if zxy.z <= 6 {
			result, err := queryTile(c, zxy)
			resultHash := md5.Sum(result.tile)
			if err != nil {
				log.Fatalf("z: %d x: %d y: %d error: %s", zxy.z, zxy.x, zxy.y, err.Error())
			}
			results <- result

			zxy := zxy
			wg.Add(4)
			if zxy.z < *maxZoom {
				go func() {
					jobs <- TileZxy{zxy.z + 1, zxy.x * 2, zxy.y * 2, resultHash}
					jobs <- TileZxy{zxy.z + 1, zxy.x*2 + 1, zxy.y * 2, resultHash}
					jobs <- TileZxy{zxy.z + 1, zxy.x * 2, zxy.y*2 + 1, resultHash}
					jobs <- TileZxy{zxy.z + 1, zxy.x*2 + 1, zxy.y*2 + 1, resultHash}
				}()
			}
		} else {
			var stack []TileZxy
			stack = append(stack, zxy)
			for len(stack) > 0 {
				zxy := stack[len(stack)-1]
				stack = stack[:len(stack)-1]

				result, err := queryTile(c, zxy)
				resultHash := md5.Sum(result.tile)
				if err != nil {
					log.Fatalf("z: %d x: %d y: %d error: %s", zxy.z, zxy.x, zxy.y, err.Error())
				}
				results <- result

				if zxy.z < *maxZoom && (bytes.Compare(zxy.parentHash[:], resultHash[:]) != 0 || zxy.z < 10) {
					stack = append(stack, TileZxy{zxy.z + 1, zxy.x * 2, zxy.y * 2, resultHash})
					stack = append(stack, TileZxy{zxy.z + 1, zxy.x*2 + 1, zxy.y * 2, resultHash})
					stack = append(stack, TileZxy{zxy.z + 1, zxy.x * 2, zxy.y*2 + 1, resultHash})
					stack = append(stack, TileZxy{zxy.z + 1, zxy.x*2 + 1, zxy.y*2 + 1, resultHash})
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
			// if ((res.z >= 0) && (res.z <= 6) && (res.executionTime >= time.Second*60)) ||
			// 	((res.z >= 7) && (res.z <= 10) && (res.executionTime >= time.Second*30)) ||
			// 	((res.z >= 11) && (res.executionTime >= time.Second*5)) {
			log.Printf("z: %d, x: %d, y: %d, bytes: %d, execution time: %s", res.z, res.x, res.y, len(res.tile), res.executionTime)
			// }
			if len(*outputPath) > 0 {
				err = fsWriteTile(*outputPath, res.z, res.x, res.y, res.tile)
			}
			if mbtiles != nil {
				err = mbtilesWriteTile(mbtiles, res.z, res.x, res.y, res.tile)
			}

			if err != nil {
				log.Fatalf("z: %d x: %d y: %d error: %s", res.z, res.x, res.y, err.Error())
			}
		case <-readDone:
			close(jobs)
			break loop
		}
	}

	if mbtiles != nil {
		err := mbtilesCreateIndexes(mbtiles)
		if err != nil {
			log.Fatal(err)
		}
	}
}
