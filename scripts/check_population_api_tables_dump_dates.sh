#!/bin/bash
# assume that dateformat is always yyyy-MM-dd hh:mm:ss and strings could be compared as date
DATE_AWS=`/usr/local/bin/aws s3 ls s3://geodata-eu-central-1-kontur/private/geocint/prod/population_api_tables.sqld.gz --profile geocint_pipeline_sender --output text | grep "population_api_tables.sqld.gz$" | cut -d " " -f1,2`
echo "AWS mtime is ${DATE_AWS}"
DATE_LOCAL=`stat data/population/population_api_tables.sqld.gz | grep "Modify" | cut -d " " -f2,3 | cut -d "." -f1`
echo "local mtime is ${DATE_LOCAL}"

if [[ "$DATE_AWS" < "$DATE_LOCAL" ]]; then
  exit 1
else
  exit 0
fi