#!/usr/bin/env bash

SENTINEL_TIF_LOCATION=/home/gis/sentinel-2-2019/2019/6/10
NDVI_TIF_LOCATION=/home/gis/geocint/data/ndvi_2019_6_10
# consider to make as parameters

cd $NDVI_TIF_LOCATION
for d in ${SENTINEL_TIF_LOCATION}/*; do
    cd "$d"
    SUBFOLDERNAME=${d: -3}
    python3 /usr/bin/gdal_calc.py -A B04.tif -B B08.tif --calc="((1.0*B-1.0*A)/(1.0*B+1.0*A))" --type=Float32 --overwrite --NoDataValue=1.001 --outfile=ndvi_$SUBFOLDERNAME.tif
    GDAL_CACHEMAX=10000 GDAL_NUM_THREADS=16 gdalwarp -t_srs EPSG:4326 -of COG ndvi_$SUBFOLDERNAME.tif $NDVI_TIF_LOCATION/ndvi_${SUBFOLDERNAME}_4326.tif
    rm ndvi_$SUBFOLDERNAME.tif
    cd $SENTINEL_TIF_LOCATION
done

cd ~/geocint
