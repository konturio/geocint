#!/usr/bin/env bash

x0=1
y0=1
zoom=0

for (( z=$zoom; z<=7; z++ )); do
  let "x0 = 2**$z"
  let "y0 = 2**$z"
  for (( x=0; x<$x0; x++ )); do
    mkdir -p data/tiles/$1/$z/$x
    for (( y=0; y<$y0; y++ )); do
      file="data/tiles/$1/$z/$x/$y.mvt"
      echo "psql -q -X -f scripts/$1.sql -v x=$x -v y=$y -v z=$z | xxd -r -p > $file"
    done
  done
done
