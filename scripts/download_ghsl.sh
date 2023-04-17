#!/bin/bash

# this script downloads all GHS_POP_GLOBE_R2022A zipped rasters
# and imports result into db

ghsl_zip_dir=data/in/ghsl
mkdir -p $ghsl_zip_dir

# if at some point there were some issues during downloading, delete file w/ errors and try again
rm -f $ghsl_zip_dir/_download-errors.log

# years required - 1975-2015
seq 8 | xargs -I {} expr 1970 + {} \* 5 | xargs -I {} \
    wget -nc -P $ghsl_zip_dir -nv --rejected-log=$ghsl_zip_dir/_download-errors.log -nc \
    http://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2022A/GHS_POP_E{}_GLOBE_R2022A_54009_100/V1-0/GHS_POP_E{}_GLOBE_R2022A_54009_100_V1_0.zip

# if some files were not downloaded - stop the script
if [ -f $ghsl_zip_dir/_download-errors.log ]; then exit 1; fi

# import into DB
# import directly from zip file
# example: 
# f=data/in/ghsl/GHS_POP_E1975_GLOBE_R2022A_54009_100_V1_0.zip
# /vsizip/data/in/ghsl/GHS_POP_E1975_GLOBE_R2022A_54009_100_V1_0.zip/GHS_POP_E1975_GLOBE_R2022A_54009_100_V1_0.tif
# TODO: raster2pgsql does not use parameter max_rows_per_copy, very slow
for f in $ghsl_zip_dir/GHS_POP_E*_GLOBE_R2022A_54009_100_V1_0.zip
do
    raster2pgsql -I -d -M -Y -s 54009 -t auto -e "/vsizip/${f}/${f:13:41}.tif" ${f:13:41}| psql -q
done