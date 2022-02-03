#!/bin/bash

mkdir data
ln -s data /persisted-volume/data
mkdir db
ln -s db /persisted-volume/db
mkdir deploy
ln -s deploy /persisted-volume/deploy

make -j data/basemap.mbtiles
