#!/usr/bin/env bash

x0=1
y0=1
zoom=0

for (( z=$zoom; z<=9; z++ )); do
  let "x0 = 2**$z"
  let "y0 = 2**$z"
  for (( x=0; x<$x0; x++ )); do
    mkdir -p data/tiles/osm_quality_bivariate/tiles/$z/$x
    for (( y=0; y<$y0; y++ )); do
      echo $z, $x, $y
      file="data/tiles/osm_quality_bivariate/tiles/$z/$x/$y.pbf"
      echo "psql -q -X -f scripts/bivariate_class_tile.sql -v x=$x -v y=$y -v z=$z | xxd -r -p > $file"
    done
  done
done
