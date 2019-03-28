#!/bin/bash

set -e

x0=1
y0=1
zoom=0

function bivariate_class() {
  tz=$1
  tx=$2
  ty=$3
  echo "
  COPY (
    SELECT encode(ST_AsMVT(q, 'bivariate_class', 4096, 'geom'), 'hex')
    FROM (
      SELECT bivariate_class,
        ST_AsMvtGeom(
          geom,
          TileBBox($tz, $tx, $ty),
          4096,
          256,
          true
        ) AS geom
      FROM osm_quality_bivariate_grid_1000
      WHERE geom && TileBBox($tz, $tx, $ty)
      AND ST_Intersects(geom, TileBBox($tz, $tx, $ty))
    ) AS q
  ) TO STDOUT;
  "
}

for (( z=$zoom; z<=9; z++ )); do
  let "x0 = 2**$z"
  let "y0 = 2**$z"
  for (( x=0; x<$x0; x++ )); do
    mkdir -p ./tiles/$z/$x
    for (( y=0; y<$y0; y++ )); do
      echo $z, $x, $y
      file="./tiles/$z/$x/$y.pbf"
      {
        psql gis gis -tq -c "$(bivariate_class $z $x $y)" | xxd -r -p ;
      } > $file
      du -h $file
    done
  done
done

scp -C tiles user@server:/var/www/tiles
