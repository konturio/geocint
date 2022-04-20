#!/bin/bash
status_code=$(curl -X $1 --write-out %{http_code} --silent --output /dev/null $2 )

if [[ "$status_code" -ne $3 ]] ; then
  echo "Returned status is not $3, got $status_code instead"; exit 1;
else
  echo "Returned status is $status_code as expected"; exit 0
fi

