package main

import (
	"bytes"
	"context"
	"flag"
	"fmt"
	"github.com/jackc/pgx/v4/pgxpool"
	"io"
	"log"
	"math"
	"os"
	"sync"
	"time"
)

// example usage: tile-generator --parallel-limit 10 --min-zoom 7 --max-zoom 7 --sql 'select basemap($1, $2, $3)' --db-config 'host=localhost dbname=gis'
var maxParallel = flag.Int("parallel-limit", 32, "parallel limit")
var minZoom = flag.Int("min-zoom", 0, "min zoom")
var maxZoom = flag.Int("max-zoom", 8, "max zoom")
var sql = flag.String("sql", "", "sql")
var dbConfig = flag.String("db-config", "", "db config")

var globalDb *pgxpool.Pool = nil

func dbConnect() (*pgxpool.Pool, error) {
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

func BuildTile(zxy TileZxy, zxys chan TileZxy, wg *sync.WaitGroup, sem chan struct{}) error {
	defer wg.Done()

	if zxy.z > *maxZoom {
		return nil
	}

	sem <- struct{}{}

	db, err := dbConnect()
	if err != nil {
		fmt.Println(err)
		return err
	}

	dir := fmt.Sprintf("%d/%d", zxy.z, zxy.x)
	filePath := fmt.Sprintf("%d/%d/%d.pbf", zxy.z, zxy.x, zxy.y)

	// Get the data
	row := db.QueryRow(context.Background(), *sql, zxy.z, zxy.x, zxy.y)
	var mvtTile []byte
	err = row.Scan(&mvtTile)
	if err != nil {
		fmt.Println(err)
		return err
	}

	err = os.MkdirAll(dir, 0777)
	if err != nil {
		return err
	}

	// Create the file
	out, err := os.Create(filePath)
	if err != nil {
		return err
	}
	defer out.Close()

	// Write the body to file
	bytes, err := io.Copy(out, bytes.NewReader(mvtTile))

	log.Printf("z: %d x: %d y: %d bytes: %d", zxy.z, zxy.x, zxy.y, bytes)

	if bytes != 0 || zxy.z < 10 {
		zxys <- TileZxy{zxy.z + 1, zxy.x * 2, zxy.y * 2}
		zxys <- TileZxy{zxy.z + 1, zxy.x*2 + 1, zxy.y * 2}
		zxys <- TileZxy{zxy.z + 1, zxy.x * 2, zxy.y*2 + 1}
		zxys <- TileZxy{zxy.z + 1, zxy.x*2 + 1, zxy.y*2 + 1}
	}

	<-sem

	return err
}

func main() {
	flag.Parse()

	zxys := make(chan TileZxy)
	wg := sync.WaitGroup{}

	go func() {
		z := *minZoom
		for x := 0; x < int(math.Pow(float64(2), float64(z))); x++ {
			for y := 0; y < int(math.Pow(float64(2), float64(z))); y++ {
				zxys <- TileZxy{z, x, y}
			}
		}
	}()

	go func() {
		time.Sleep(1000 * time.Millisecond)
		wg.Wait()
		close(zxys)
	}()

	sem := make(chan struct{}, *maxParallel)

	for zxy := range zxys {
		wg.Add(1)
		go BuildTile(zxy, zxys, &wg, sem)
	}
}
