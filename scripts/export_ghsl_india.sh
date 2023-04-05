#!/bin/bash

# this script clips rasters in db
# converts to hexagons with integer population
# exports result as gpkg

ghsl_zip_dir=data/in/ghsl
export_zip_dir=data/out/ghsl_india

mkdir -p $export_zip_dir

for f in $ghsl_zip_dir/GHS_POP_E*_GLOBE_R2022A_54009_100_V1_0.zip
do
    # example: "${f:13:41}" results in "GHS_POP_E1980_GLOBE_R2022A_54009_100_V1_0"
    tab_name=${f:13:41}
    tab_result="${tab_name}_h3_r8_geom"
    psql -v tab_name=$tab_name -v tab_result=$tab_result -f ghsl_pop_india_snapshot.sql
    psql -c "delete from ${tab_result} where population = 0;"
    # exporting table
    ogr2ogr -overwrite -f GPKG $export_zip_dir/$tab_result.gpkg PG:'dbname=gis' $tab_result -nln $tab_result -lco OVERWRITE=yes
done