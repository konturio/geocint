#!/bin/bash
# $1 - table with data
# $2 - column name with indicator value
# $3 - name of output csv file

table_name=$1
indicator_value=$2
output_csv=$3

# Stream the CSV directly through pigz to keep it compressed on disk
psql -q -X -c "copy (select h3, ${indicator_value} from ${table_name} where h3 is not null and ${indicator_value} is not null) to stdout with delimiter ',' csv;" | pigz -9 > "$output_csv"
