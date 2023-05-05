#!/bin/bash

# this script downloads all GHS_POP_GLOBE_R2022A zipped rasters
# and imports result into db

ghsl_zip_dir=data/in/ghsl
mkdir -p $ghsl_zip_dir

# if at some point there were some issues during downloading, delete file w/ errors and try again
rm -f $ghsl_zip_dir/_download-errors.log

# years required - 1975-2030
# but filenames for years > 2020 differs
# so there are two downloads
seq 9 | xargs -I {} expr 1970 + {} \* 5 | xargs -I {} \
    wget -nc -P $ghsl_zip_dir -nv --rejected-log=$ghsl_zip_dir/_download-errors.log -nc \
    http://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2022A/GHS_POP_E{}_GLOBE_R2022A_54009_100/V1-0/GHS_POP_E{}_GLOBE_R2022A_54009_100_V1_0.zip

seq 2 | xargs -I {} expr 2020 + {} \* 5 | xargs -I {} \
    wget -nc -P $ghsl_zip_dir -nv --rejected-log=$ghsl_zip_dir/_download-errors.log -nc \
    http://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2022A/GHS_POP_P{}_GLOBE_R2022A_54009_100/V1-0/GHS_POP_P{}_GLOBE_R2022A_54009_100_V1_0.zip

# if some files were not downloaded - stop the script
if [ -f $ghsl_zip_dir/_download-errors.log ]; then exit 1; fi

# import into DB
# import directly from zip file
# example:
# input_file=data/in/ghsl/GHS_POP_E1975_GLOBE_R2022A_54009_100_V1_0.zip ->
# raster_file=/vsizip/data/in/ghsl/GHS_POP_E1975_GLOBE_R2022A_54009_100_V1_0.zip/GHS_POP_E1975_GLOBE_R2022A_54009_100_V1_0.tif
# TODO: raster2pgsql does not use parameter max_rows_per_copy, very slow
func_to_run_in_parallel(){
    input_file=$1
    raster_file="/vsizip/${input_file}/${input_file:13:41}.tif"
    tabname="lgudyma.${input_file:13:41}"
    raster2pgsql -d -M -Y -s 54009 -t auto -e $raster_file $tabname | psql -q;
}

export -f func_to_run_in_parallel

ls $ghsl_zip_dir/*.zip | parallel func_to_run_in_parallel {}