#!/bin/bash

ln -s /basemap /data/basemap
ln -s /tile_generator /data/tile_generator
ln -s /Makefile /data/Makefile
cd /data
make -j data/basemap.mbtiles
