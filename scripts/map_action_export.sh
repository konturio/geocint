#!/bin/sh
PSQL_SELECT='psql -q -t -U gis -c'
OUTDIR=data/out/map_action/

layers=$(${PSQL_SELECT} "SELECT distinct ma_theme FROM lgudyma.map_action;")

for layer in ${layers}; do
    ogr2ogr -f "ESRI Shapefile" ${OUTDIR}map_action_${layer}.shp PG:"dbname=gis" -sql "SELECT * FROM lgudyma.map_action WHERE ma_theme = '${layer}'"
done