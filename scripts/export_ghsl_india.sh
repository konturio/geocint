#!/bin/bash

# this script runs sql script for each dataset
# and exports result as gpkg

ghsl_zip_dir=data/in/ghsl
export_zip_dir=data/out/ghsl_india

mkdir -p $export_zip_dir

for f in $ghsl_zip_dir/GHS_POP_E*_GLOBE_R2022A_54009_100_V1_0.zip
do
    # example: "${f:13:41}" results in "GHS_POP_E1980_GLOBE_R2022A_54009_100_V1_0"
    tab_name=${f:13:41}
    tab_temp="${tab_name}_temp"
    tab_result="${tab_name}_h3_r8_geom"
    psql -v tab_name=$tab_name -v tab_result=$tab_result -v tab_temp=$tab_temp -f ghsl_pop_india_snapshot.sql
    psql -c "delete from ${tab_result} where population = 0;"
    psql -c "create index on ${tab_result} using gist(geom);"
    # selecting only hexagons that intersect with India polygon
    # and exporting table to gpkg
    file_export="kontur_population_IN_${tab_result:9:4}"
    ogr2ogr -overwrite -f GPKG $export_zip_dir/$tab_result.gpkg PG:'dbname=gis' $tab_result -nln $file_export -lco OVERWRITE=yes -sql "select a.* from ${tab_result} as a, kontur_boundaries as b where st_intersects(a.geom, b.geom) and osm_id = 304716"
done