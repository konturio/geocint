#!/bin/sh
PSQL_SELECT='psql -t -A -U gis -c'
OUTDIR=data/out/map_action/

layers=$(${PSQL_SELECT} "SELECT distinct ma_theme FROM lgudyma.map_action LIMIT 2;")

for layer in ${layers}; do
    ogr2ogr -f "ESRI Shapefile" ${OUTDIR}map_action_${layer} PG:"dbname=gis" -sql "select * from lgudyma.map_action where ma_theme = '${layer}'"
done