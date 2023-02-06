#!/bin/bash
# $1 - table with data
# $2 - column name with indicator value
# $3 - scaling coefficient
# $4 - number of digits to keep after point
# $5 - name of output csv file
table_name=$1
indicator_value=$2
scaling_coefficient=$3
digits_after_point=$4
output_csv=$5
psql -q -X -c "copy (select distinct h3, trunc((${indicator_value} * ${scaling_coefficient})::numeric, ${digits_after_point}) from ${table_name} where h3 is not null and ${indicator_value} is not null) to stdout with delimiter ',' csv;" > ${output_csv}