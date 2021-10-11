package main

import (
	"bytes"
	"context"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"math"
	"os"
	"sync"
	"time"
	"path"
	"strconv"
	"github.com/jackc/pgx/v4"
	"github.com/jackc/pgx/v4/pgxpool"
)

// example usage: tile-generator --parallel-limit 10 --min-zoom 7 --max-zoom 7 --sql 'select basemap(:z, :x, :y)' --db-config 'host=localhost dbname=gis'
var maxParallel = flag.Int("j", 32, "parallel limit")
var minZoom = flag.Int("min-zoom", 0, "min zoom")
var maxZoom = flag.Int("max-zoom", 8, "max zoom")
var sqlQueryFilepath = flag.String("sql-query-filepath", "", "sql query file path")
var dbConfig = flag.String("db-config", "", "db config")
var outputPath = flag.String("output-path", ".", "output path")

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

type TileZxy struct {
	z, x, y int
}

func BuildTile(db *pgxpool.Pool, zxy TileZxy, wg *sync.WaitGroup, sem chan struct{}) error {
	defer wg.Done()

	if zxy.z > *maxZoom {
		return nil
	}

	if zxy.z <= 4 {
		wg.Add(4)
		
		go BuildTile(db, TileZxy{zxy.z + 1, zxy.x * 2, zxy.y * 2}, wg, sem)
		go BuildTile(db, TileZxy{zxy.z + 1, zxy.x*2 + 1, zxy.y * 2}, wg, sem)
		go BuildTile(db, TileZxy{zxy.z + 1, zxy.x * 2, zxy.y*2 + 1}, wg, sem)
		go BuildTile(db, TileZxy{zxy.z + 1, zxy.x*2 + 1, zxy.y*2 + 1}, wg, sem)
	}

	sem <- struct{}{}

	dir := path.Join(*outputPath, fmt.Sprintf("%d/%d", zxy.z, zxy.x))
	filePath := path.Join(*outputPath, fmt.Sprintf("%d/%d/%d.mvt", zxy.z, zxy.x, zxy.y))

	// Get the data
	row := db.QueryRow(context.Background(), "query_tile", strconv.Itoa(zxy.z), strconv.Itoa(zxy.x), strconv.Itoa(zxy.y))
	var mvtTile []byte
	err := row.Scan(&mvtTile)
	if err != nil {
		log.Fatalf("z: %d x: %d y: %d error: %s", zxy.z, zxy.x, zxy.y, err.Error())
	}

	err = os.MkdirAll(dir, 0777)
	if err != nil {
		log.Fatalf("z: %d x: %d y: %d error: %s", zxy.z, zxy.x, zxy.y, err.Error())
	}

	// Create the file
	out, err := os.Create(filePath)
	if err != nil {
		log.Fatalf("z: %d x: %d y: %d error: %s", zxy.z, zxy.x, zxy.y, err.Error())
	}

	// Write the body to file
	bytes, err := io.Copy(out, bytes.NewReader(mvtTile))
	if err != nil {
		log.Fatalf("z: %d x: %d y: %d error: %s", zxy.z, zxy.x, zxy.y, err.Error())
	}
	out.Close()

	<-sem

	log.Printf("z: %d x: %d y: %d bytes: %d", zxy.z, zxy.x, zxy.y, bytes)

	if zxy.z > 4 && (bytes != 0 || zxy.z < 10) {
		wg.Add(4)
		
		go BuildTile(db, TileZxy{zxy.z + 1, zxy.x * 2, zxy.y * 2}, wg, sem)
		go BuildTile(db, TileZxy{zxy.z + 1, zxy.x*2 + 1, zxy.y * 2}, wg, sem)
		go BuildTile(db, TileZxy{zxy.z + 1, zxy.x * 2, zxy.y*2 + 1}, wg, sem)
		go BuildTile(db, TileZxy{zxy.z + 1, zxy.x*2 + 1, zxy.y*2 + 1}, wg, sem)
	}

	return err
}

func main() {
	flag.Parse()

	tileSql, err := ioutil.ReadFile(*sqlQueryFilepath)
	if err != nil {
		log.Fatal(err)
	}

	wg := sync.WaitGroup{}

	sem := make(chan struct{}, *maxParallel)

	db, err := dbConnect(string(tileSql))
	if err != nil {
		log.Fatal(err)
		return
	}

	z := *minZoom
	for x := 0; x < int(math.Pow(float64(2), float64(z))); x++ {
		for y := 0; y < int(math.Pow(float64(2), float64(z))); y++ {
			wg.Add(1)
			go BuildTile(db, TileZxy{z, x, y}, &wg, sem)
		}
	}

	wg.Wait()
	close(sem)
}
