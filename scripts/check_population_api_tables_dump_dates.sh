#!/bin/bash
# assume that dateformat is always yyyy-MM-dd hh:mm:ss and strings could be compared as date
DATE_AWS_BV=`/usr/local/bin/aws s3 ls s3://geodata-eu-central-1-kontur/private/geocint/prod/bivariate_tables_prod.sqld.gz --profile geocint_pipeline_sender --output text | grep "bivariate_tables_prod.sqld.gz$" | cut -d " " -f1,2`
echo "AWS bivariate_tables_prod dump mtime is ${DATE_AWS_BV}"
DATE_LOCAL_BV=`stat data/out/population/bivariate_tables_prod.sqld.gz | grep "Modify" | cut -d " " -f2,3 | cut -d "." -f1`
echo "local bivariate_tables_prod dump mtime is ${DATE_LOCAL_BV}"
DATE_AWS_STATH3=`/usr/local/bin/aws s3 ls s3://geodata-eu-central-1-kontur/private/geocint/prod/stat_h3_prod.sqld.gz --profile geocint_pipeline_sender --output text | grep "stat_h3_prod.sqld.gz$" | cut -d " " -f1,2`
echo "AWS stat_h3_prod dump mtime is ${DATE_AWS_STATH3}"
DATE_LOCAL_STATH3=`stat data/out/population/stat_h3_prod.sqld.gz | grep "Modify" | cut -d " " -f2,3 | cut -d "." -f1`
echo "local stat_h3_prod dump mtime is ${DATE_LOCAL_STATH3}"

if [[ "$DATE_AWS_BV" < "$DATE_LOCAL_BV" ]] || [[ "$DATE_AWS_STATH3" < "$DATE_LOCAL_STATH3" ]]; then
  exit 1
else
  exit 0
fi