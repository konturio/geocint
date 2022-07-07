#!/bin/bash
# checks if file ($1 parameter, file location) size in MB not less than  $2 parameter

file_size_mb=$(ls -l --b=MB $1 | cut -d " " -f5 | sed 's/MB//g')

if [[ "$file_size_mb" -le $2 ]] ; then
  echo "File size is less than $2 MB, test failed"; exit 1;
else
  echo "File size is bigger than $2 MB, test passed"; exit 0
fi
