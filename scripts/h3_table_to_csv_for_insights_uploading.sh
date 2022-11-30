#!/bin/bash
# $1 - table with data
# $2 - column name with indicator value
# $3 - name of output csv file
table_name=$1
indicator_value=$2
output_csv=$3
psql -q -X -c "copy (select h3, ${indicator_value} from ${table_name}) to stdout with delimiter ',' csv;" > ${output_csv}