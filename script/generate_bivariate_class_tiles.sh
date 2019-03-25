#!/bin/bash

set -e

x0=0
y0=0
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
          TileBBox($tz, $tx, $tz),
          4096,
          256,
          true
        ) AS geom
      FROM osm_quality_bivariate_grid_1000
      WHERE geom && TileBBox($tz, $tx, $tz)
      AND ST_Intersects(geom, TileBBox($tz, $tx, $tz))
    ) AS q;
  ) TO STDOUT;
  "
}

offset=1

for (( z=$zoom; z<=9; ++z )); do
  for (( x=$x0-$offset; x<=$x0+$offset; ++x )); do
    mkdir -p ./tiles/$z/$x
    for (( y=$y0-$offset; y<=$y0+$offset; ++y )); do
      file="./tiles/$z/$x/$y.pbf"
      {
        psql gis gis -tq -c "$(bivariate_class $z $x $y)" | xxd -r -p ;
      } > $file
      du -h $file
    done
  done
  let "offset *= 2"
  let "x0 = x0 * 2"
  let "y0 = y0 * 2"
done
