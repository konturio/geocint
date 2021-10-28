package main

import (
	"bytes"
	"context"
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
	"github.com/gen0cide/waiter"
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
	z, x, y int
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

func mbtilesWriteTile(db *sql.DB, zxy TileZxy, tile []byte) error {
	stmt, err := db.Prepare("insert into tiles (zoom_level, tile_column, tile_row, tile_data) values (?, ?, ?, ?)")
	if err != nil {
		return err
	}
	defer stmt.Close()

	_, err = stmt.Exec(zxy.z, zxy.x, (1<<zxy.z)-1-zxy.y, tile)
	return err
}

func fsWriteTile(outputPath string, zxy TileZxy, tile []byte) error {
	dir := path.Join(outputPath, fmt.Sprintf("%d/%d", zxy.z, zxy.x))
	filePath := path.Join(outputPath, fmt.Sprintf("%d/%d/%d.mvt", zxy.z, zxy.x, zxy.y))

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
		dbPoolMaxLifeTime, _ := time.ParseDuration("1h")
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

func queryTile(db *pgxpool.Pool, zxy TileZxy) (ResultTile, error) {
	tileQueryStartTime := time.Now()
	row := db.QueryRow(context.Background(), "query_tile", strconv.Itoa(zxy.z), strconv.Itoa(zxy.x), strconv.Itoa(zxy.y))
	var tile []byte
	err := row.Scan(&tile)
	tileQueryElapsedTime := time.Since(tileQueryStartTime)

	return ResultTile{zxy.z, zxy.x, zxy.y, tile, tileQueryElapsedTime}, err
}

func worker(db *pgxpool.Pool, jobs chan TileZxy, results chan<- ResultTile, wg *waiter.Waiter) {
	for zxy := range jobs {
		result, err := queryTile(db, zxy)
		if err != nil {
			log.Fatalln("z: %d x: %d y: %d error: %s", zxy.z, zxy.x, zxy.y, err.Error())
		}

		results <- result

		if zxy.z < *maxZoom && (len(result.tile) != 0 || zxy.z < 10) {
			zxy := zxy
			wg.Add(4)
			go func() {
				jobs <- TileZxy{zxy.z + 1, zxy.x * 2, zxy.y * 2}
				jobs <- TileZxy{zxy.z + 1, zxy.x*2 + 1, zxy.y * 2}
				jobs <- TileZxy{zxy.z + 1, zxy.x * 2, zxy.y*2 + 1}
				jobs <- TileZxy{zxy.z + 1, zxy.x*2 + 1, zxy.y*2 + 1}
			}()
		}

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
	wg := waiter.New("tiles", os.Stdout)

	for i := 0; i < *maxParallel; i++ {
		go worker(db, jobs, results, wg)
	}

	z := *minZoom
	for x := 0; x < int(math.Pow(float64(2), float64(z))); x++ {
		for y := 0; y < int(math.Pow(float64(2), float64(z))); y++ {
			wg.Add(1)
			zxy := TileZxy{z, x, y}
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
			if ((res.z >= 0) && (res.z <= 6) && (res.executionTime >= time.Second*60)) ||
				((res.z >= 7) && (res.z <= 10) && (res.executionTime >= time.Second*30)) ||
				((res.z >= 11) && (res.executionTime >= time.Second*5)) {
				log.Println("slow tile z: %d, x: %d, y: %d, bytes: %d, execution time: %s", res.z, res.x, res.y, len(res.tile), res.executionTime)
			}
			if len(*outputPath) > 0 {
				err = fsWriteTile(*outputPath, TileZxy{res.z, res.x, res.y}, res.tile)
			}
			if mbtiles != nil {
				err = mbtilesWriteTile(mbtiles, TileZxy{res.z, res.x, res.y}, res.tile)
			}

			if err != nil {
				log.Fatalln("z: %d x: %d y: %d error: %s", res.z, res.x, res.y, err.Error())
			}
		case <-readDone:
			close(jobs)
			break loop
		}
	}
}
