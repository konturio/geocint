#!/bin/bash
# Inputs:
# $1 - source vector dataset
# $2 - name of layer inside vector dataset
# $3 - directory for storing calculations and results (without ending /)
# $4 - output proximity geotif with path


# Constants
output_resolution_deg=0.005
output_resolution_m=500

zones_overlap=6 # how many degrees to overlap with zones to the left and right. Must be sychronized with utm_left and utm_right

# these values must be syncronized with utm values
north_top=85
north_bottom=-6
south_top=6
south_bottom=-85

normal_width_deg=3600 # 18 degrees / 0.005
normal_height_deg=17400 # 87 degrees / 0.005
edge_width_deg=2400 # 12 degrees / 0.005

utm_left=-500000 # left edge of left neighbour zone
utm_right=1500000 # right edge of right neighbour zone
utm_north_top=9000000 # ~85 deg
utm_north_bottom=-600000 # ~6 deg overlap with southern zone
utm_south_top=10600000 # ~6 deg overlap with northern zone
utm_south_bottom=2500000 # ~-85 deg

full_width_deg=72000 # full map 360 deg / 0.005
full_height_deg=34000 # full map 170 deg / 0.005 (-85;85)


# Rasterize at wgs84
# gdal_rasterize -burn 1 -of GTiff -te -180 ${south_bottom} 180 ${north_top} -tr ${output_resolution} ${output_resolution} -ot Byte $1 $3/rasterized.tif 

# Create dir for parts
mkdir -p $3

for zone in {01..60}
do
  # Calculate left and right borders of current 
  current_left_deg=$((-1*180+10#$zone*6-6-$zones_overlap))
  if [[ $current_left_deg -lt -180 ]]
  then
    current_left_deg=-180
  fi 
  current_right_deg=$((-1*180+10#$zone*6+$zones_overlap))
  if [[ $current_right_deg -gt 180 ]]
  then
    current_right_deg=180
  fi
  echo "left: $current_left_deg ; right: $current_right_deg"
  
  # Zone codes
  current_north_epsg_zone="EPSG:326${zone}"
  current_south_epsg_zone="EPSG:327${zone}"
  echo "current north zone is ${current_north_epsg_zone}"  
  echo "current south zone is ${current_south_epsg_zone}"

  # Step 1. Get vector data for zone
  # Over WGS84 with overlap
  ogr2ogr -f GPKG -spat_srs EPSG:4326 -t_srs ${current_north_epsg_zone} -spat ${current_left_deg} ${north_bottom} ${current_right_deg} ${north_top} $3/north_part_${zone}_vector.gpkg $1
  ogr2ogr -f GPKG -spat_srs EPSG:4326 -t_srs ${current_south_epsg_zone} -spat ${current_left_deg} ${south_bottom} ${current_right_deg} ${south_top} $3/south_part_${zone}_vector.gpkg $1
  # Over current UTM zone with overlap - deprecated, slow
  # ogr2ogr -f GPKG -spat_srs ${current_north_epsg_zone} -t_srs ${current_north_epsg_zone} -spat ${utm_left} ${utm_north_bottom} ${utm_right} ${utm_north_top} $3/north_part_${zone}_vector.gpkg $1
  # ogr2ogr -f GPKG -spat_srs ${current_south_epsg_zone} -t_srs ${current_south_epsg_zone} -spat ${utm_left} ${utm_south_bottom} ${utm_right} ${utm_south_top} $3/south_part_${zone}_vector.gpkg $1
 
  # Calculate number of features to filter out empty regions
  north_features=$(ogrinfo -so $3/north_part_${zone}_vector.gpkg $2 | grep -Po 'Feature Count: \K.*')
  south_features=$(ogrinfo -so $3/south_part_${zone}_vector.gpkg $2 | grep -Po 'Feature Count: \K.*')
 
  # Step 2. Rasterize it and calculate proximity. If there is no features - just generate empty raster
  if [[ $north_features -eq 0 ]]
  then
    echo "-- North - no features!"
	echo "Create empty global grid"
    GDAL_NUM_THREADS=16 gdal_create -a_ullr -180 ${south_bottom} 180 ${north_top} -ot Float32 -co compress=deflate -burn 999999999999999 -a_nodata 999999999999999 -bands 1 -outsize ${full_width_deg} ${full_height_deg} -a_srs EPSG:4326 $3/north_part_${zone}_proximity_wgs.tif
	echo "DONE - Create empty global grid"
  else
    echo "-- North --"
    echo "Rasterizing..."
    GDAL_NUM_THREADS=16 gdal_rasterize -burn 1 -at -of GTiff -tr ${output_resolution_m} ${output_resolution_m} -te ${utm_left} ${utm_north_bottom} ${utm_right} ${utm_north_top} -ot Byte $3/north_part_${zone}_vector.gpkg $3/north_part_${zone}_vector_rasterized.tif 
	echo "DONE - Rasterizing..."
	echo "Calculating proximity map..."
    GDAL_NUM_THREADS=16 gdal_proximity.py -srcband 1 -distunits GEO -values 1 -ot Float32 -of GTiff $3/north_part_${zone}_vector_rasterized.tif $3/north_part_${zone}_proximity.tif
    GDAL_NUM_THREADS=16 gdalwarp -t_srs EPSG:4326 -co compress=deflate -dstnodata 999999999999999 -te -180 ${south_bottom} 180 ${north_top} -tr ${output_resolution_deg} ${output_resolution_deg} $3/north_part_${zone}_proximity.tif $3/north_part_${zone}_proximity_wgs.tif
	echo "DONE - Calculating proximity map..."
  fi

  if [[ $south_features -eq 0 ]]
  then
    echo "-- South - no features!"
	echo "Create empty global grid"
    GDAL_NUM_THREADS=16 gdal_create -a_ullr -180 ${south_bottom} 180 ${north_top} -ot Float32 -co compress=deflate -burn 999999999999999 -a_nodata 999999999999999 -bands 1 -outsize ${full_width_deg} ${full_height_deg} -a_srs EPSG:4326 $3/south_part_${zone}_proximity_wgs.tif
	echo "DONE - Create empty global grid"
  else
    echo "-- South --"
	echo "Rasterizing..."
    GDAL_NUM_THREADS=16 gdal_rasterize -burn 1 -at -of GTiff -tr ${output_resolution_m} ${output_resolution_m} -te ${utm_left} ${utm_south_bottom} ${utm_right} ${utm_south_top} -ot Byte $3/south_part_${zone}_vector.gpkg $3/south_part_${zone}_vector_rasterized.tif
	echo "DONE - Rasterizing..."
	echo "Calculating proximity map..."
    GDAL_NUM_THREADS=16 gdal_proximity.py -srcband 1 -distunits GEO -values 1 -ot Float32 -of GTiff $3/south_part_${zone}_vector_rasterized.tif $3/south_part_${zone}_proximity.tif
    GDAL_NUM_THREADS=16 gdalwarp -t_srs EPSG:4326 -co compress=deflate -dstnodata 999999999999999 -te -180 ${south_bottom} 180 ${north_top} -tr ${output_resolution_deg} ${output_resolution_deg} $3/south_part_${zone}_proximity.tif $3/south_part_${zone}_proximity_wgs.tif
	echo "DONE - Calculating proximity map..."
  fi
done

# Perform calculations
# North 1-30
echo "Calculate North 1-30"
GDAL_NUM_THREADS=16 gdal_calc.py --co="BIGTIFF=YES" --co="COMPRESS=DEFLATE" --hideNoData -a $3/north_part_01_proximity_wgs.tif -b $3/north_part_02_proximity_wgs.tif -c $3/north_part_03_proximity_wgs.tif -d $3/north_part_04_proximity_wgs.tif -e $3/north_part_05_proximity_wgs.tif -f $3/north_part_06_proximity_wgs.tif -g $3/north_part_07_proximity_wgs.tif -h $3/north_part_08_proximity_wgs.tif -i $3/north_part_09_proximity_wgs.tif -j $3/north_part_10_proximity_wgs.tif -k $3/north_part_11_proximity_wgs.tif -l $3/north_part_12_proximity_wgs.tif -m $3/north_part_13_proximity_wgs.tif -n $3/north_part_14_proximity_wgs.tif -o $3/north_part_15_proximity_wgs.tif -p $3/north_part_16_proximity_wgs.tif -q $3/north_part_17_proximity_wgs.tif -r $3/north_part_18_proximity_wgs.tif -s $3/north_part_19_proximity_wgs.tif -t $3/north_part_20_proximity_wgs.tif -u $3/north_part_21_proximity_wgs.tif -v $3/north_part_22_proximity_wgs.tif -w $3/north_part_23_proximity_wgs.tif -x $3/north_part_24_proximity_wgs.tif -y $3/north_part_25_proximity_wgs.tif -z $3/north_part_26_proximity_wgs.tif -A $3/north_part_27_proximity_wgs.tif -B $3/north_part_28_proximity_wgs.tif -C $3/north_part_29_proximity_wgs.tif -D $3/north_part_30_proximity_wgs.tif --outfile=$3/part1.tif --calc="minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(D,C),B),A),z),y),x),w),v),u),t),s),r),q),p),o),n),m),l),k),j),i),h),g),f),e),d),c),b),a)"

#North 31-60
echo "Calculate North 31-60"
GDAL_NUM_THREADS=16 gdal_calc.py --co="BIGTIFF=YES" --co="COMPRESS=DEFLATE" --hideNoData -a $3/north_part_31_proximity_wgs.tif -b $3/north_part_32_proximity_wgs.tif -c $3/north_part_33_proximity_wgs.tif -d $3/north_part_34_proximity_wgs.tif -e $3/north_part_35_proximity_wgs.tif -f $3/north_part_36_proximity_wgs.tif -g $3/north_part_37_proximity_wgs.tif -h $3/north_part_38_proximity_wgs.tif -i $3/north_part_39_proximity_wgs.tif -j $3/north_part_40_proximity_wgs.tif -k $3/north_part_41_proximity_wgs.tif -l $3/north_part_42_proximity_wgs.tif -m $3/north_part_43_proximity_wgs.tif -n $3/north_part_44_proximity_wgs.tif -o $3/north_part_45_proximity_wgs.tif -p $3/north_part_46_proximity_wgs.tif -q $3/north_part_47_proximity_wgs.tif -r $3/north_part_48_proximity_wgs.tif -s $3/north_part_49_proximity_wgs.tif -t $3/north_part_50_proximity_wgs.tif -u $3/north_part_51_proximity_wgs.tif -v $3/north_part_52_proximity_wgs.tif -w $3/north_part_53_proximity_wgs.tif -x $3/north_part_54_proximity_wgs.tif -y $3/north_part_55_proximity_wgs.tif -z $3/north_part_56_proximity_wgs.tif -A $3/north_part_57_proximity_wgs.tif -B $3/north_part_58_proximity_wgs.tif -C $3/north_part_59_proximity_wgs.tif -D $3/north_part_60_proximity_wgs.tif --outfile=$3/part2.tif --calc="minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(D,C),B),A),z),y),x),w),v),u),t),s),r),q),p),o),n),m),l),k),j),i),h),g),f),e),d),c),b),a)"

#South 1-30
echo "Calculate South 1-30"
GDAL_NUM_THREADS=16 gdal_calc.py --co="BIGTIFF=YES" --co="COMPRESS=DEFLATE" --hideNoData -a $3/south_part_01_proximity_wgs.tif -b $3/south_part_02_proximity_wgs.tif -c $3/south_part_03_proximity_wgs.tif -d $3/south_part_04_proximity_wgs.tif -e $3/south_part_05_proximity_wgs.tif -f $3/south_part_06_proximity_wgs.tif -g $3/south_part_07_proximity_wgs.tif -h $3/south_part_08_proximity_wgs.tif -i $3/south_part_09_proximity_wgs.tif -j $3/south_part_10_proximity_wgs.tif -k $3/south_part_11_proximity_wgs.tif -l $3/south_part_12_proximity_wgs.tif -m $3/south_part_13_proximity_wgs.tif -n $3/south_part_14_proximity_wgs.tif -o $3/south_part_15_proximity_wgs.tif -p $3/south_part_16_proximity_wgs.tif -q $3/south_part_17_proximity_wgs.tif -r $3/south_part_18_proximity_wgs.tif -s $3/south_part_19_proximity_wgs.tif -t $3/south_part_20_proximity_wgs.tif -u $3/south_part_21_proximity_wgs.tif -v $3/south_part_22_proximity_wgs.tif -w $3/south_part_23_proximity_wgs.tif -x $3/south_part_24_proximity_wgs.tif -y $3/south_part_25_proximity_wgs.tif -z $3/south_part_26_proximity_wgs.tif -A $3/south_part_27_proximity_wgs.tif -B $3/south_part_28_proximity_wgs.tif -C $3/south_part_29_proximity_wgs.tif -D $3/south_part_30_proximity_wgs.tif --outfile=$3/part3.tif --calc="minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(D,C),B),A),z),y),x),w),v),u),t),s),r),q),p),o),n),m),l),k),j),i),h),g),f),e),d),c),b),a)"

#South 31-60
echo "Calculate South 31-60"
GDAL_NUM_THREADS=16 gdal_calc.py --co="BIGTIFF=YES" --co="COMPRESS=DEFLATE" --hideNoData -a $3/south_part_31_proximity_wgs.tif -b $3/south_part_32_proximity_wgs.tif -c $3/south_part_33_proximity_wgs.tif -d $3/south_part_34_proximity_wgs.tif -e $3/south_part_35_proximity_wgs.tif -f $3/south_part_36_proximity_wgs.tif -g $3/south_part_37_proximity_wgs.tif -h $3/south_part_38_proximity_wgs.tif -i $3/south_part_39_proximity_wgs.tif -j $3/south_part_40_proximity_wgs.tif -k $3/south_part_41_proximity_wgs.tif -l $3/south_part_42_proximity_wgs.tif -m $3/south_part_43_proximity_wgs.tif -n $3/south_part_44_proximity_wgs.tif -o $3/south_part_45_proximity_wgs.tif -p $3/south_part_46_proximity_wgs.tif -q $3/south_part_47_proximity_wgs.tif -r $3/south_part_48_proximity_wgs.tif -s $3/south_part_49_proximity_wgs.tif -t $3/south_part_50_proximity_wgs.tif -u $3/south_part_51_proximity_wgs.tif -v $3/south_part_52_proximity_wgs.tif -w $3/south_part_53_proximity_wgs.tif -x $3/south_part_54_proximity_wgs.tif -y $3/south_part_55_proximity_wgs.tif -z $3/south_part_56_proximity_wgs.tif -A $3/south_part_57_proximity_wgs.tif -B $3/south_part_58_proximity_wgs.tif -C $3/south_part_59_proximity_wgs.tif -D $3/south_part_60_proximity_wgs.tif --outfile=$3/part4.tif --calc="minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(minimum(D,C),B),A),z),y),x),w),v),u),t),s),r),q),p),o),n),m),l),k),j),i),h),g),f),e),d),c),b),a)"

#finaly unite
echo "Global union"
GDAL_NUM_THREADS=16 gdal_calc.py --co="BIGTIFF=YES" --co="COMPRESS=DEFLATE" --hideNoData -a $3/part1.tif -b $3/part2.tif -c $3/part3.tif -d $3/part4.tif --outfile=$4 --calc="minimum(minimum(minimum(d,c),b),a)"

#set nodata
echo "Final setup - nodata"
gdal_edit.py -a_nodata 999999999999999 $4
echo "DONE"