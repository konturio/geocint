#!/bin/bash

# this script runs sql script for each dataset
# and exports result as gpkg

ghsl_zip_dir=data/in/ghsl
export_zip_dir=data/out/ghsl_india

mkdir -p $export_zip_dir

func_to_run_in_parallel(){
    filename=$1
    # example: "${filename:13:41}" results in "GHS_POP_E1980_GLOBE_R2022A_54009_100_V1_0"
    tab_name=${filename:13:41}
    tab_temp="${tab_name}_temp"
    tab_result="${tab_name}_h3_r8_geom"
    # generating result table in db
    psql -v tab_name=$tab_name -v tab_result=$tab_result -v tab_temp=$tab_temp -f ghsl_pop_india_snapshot.sql
    psql -c "delete from ${tab_result} where population = 0;"
    # and exporting table to gpkg
    file_export="kontur_population_IN_${tab_result:9:4}"
    ogr2ogr -overwrite -f GPKG $export_zip_dir/$tab_result.gpkg PG:'dbname=gis' $tab_result -nln $file_export -lco OVERWRITE=yes -sql "select * from ${tab_result}"
}

export -f func_to_run_in_parallel

ls $ghsl_zip_dir/*.zip | parallel func_to_run_in_parallel {}