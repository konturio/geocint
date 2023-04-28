#!/bin/bash

# this script gets hasc codes(example: 'AF') for country
# using this codes generates topology boundaries per country
# processing are made in db, see scripts/topology_boundaries_per_country_export.sql
# it runs in parallel

func_to_run_in_parallel(){
    dir_out=data/out/kontur_topology_boundaries_per_country
    country_code=$1
    export_date=$2
    table_temp="topology_tmp_${country_code}"
    table_result="topology_boundaries_${country_code}"
    file_export="topology_boundaries_${country_code}_${export_date}"
    
    psql -v tab_temp=$table_temp -v tab_result=$table_result -v cnt_code=$country_code -f scripts/topology_boundaries_per_country_export.sql
    ogr2ogr -overwrite -f GPKG $dir_out/$file_export.gpkg PG:'dbname=gis' $table_result -nln $file_export -lco OVERWRITE=yes -sql "select * from ${table_result}"
    psql -c "drop table if exists ${table_result};"
}


while IFS="," read -r country_code
do
    # run generating topology in parallel
    func_to_run_in_parallel $country_code $(date '+%Y-%m-%d') &
done < <( psql -X -q -t -F , -A -c "SELECT hasc FROM hdx_boundaries GROUP by 1")

wait