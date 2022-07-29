#!/bin/bash
# checks if number  ($1 parameter) is equal to $2 parameter
if [[ "$1" -ne $2 ]] ; then
  echo "Returned count is not $2, got $1 instead"; exit 1;
else
  echo "Returned count is $2 as expected"; exit 0
fi

