#!/bin/bash
# $1 - start date (YYYY-MM-DD)
# $2 - end date (YYYY-MM-DD)
# $3 - output file

start_date="$1"
end_date="$2"
output_file="$3"

limit=10000
offset=0

: > "$output_file"

while true; do
  response=$(curl -s \
    "https://gateway.api.globalfishingwatch.org/v2/events?datasets=public-global-fishing-events:latest&start-date=${start_date}&end-date=${end_date}&limit=${limit}&offset=${offset}&includes[]=id&includes[]=type&includes[]=start&includes[]=end&includes[]=position&includes[]=vessel.id&includes[]=portVisit.portId&includes[]=portVisit.portName&includes[]=confidence.level" \
    -H "Authorization: Bearer ${GFW_TOKEN}")

  echo "$response" | jq -c '.events[]' >> "$output_file"

  next_offset=$(echo "$response" | jq -r '.nextOffset')
  if [ "$next_offset" = "null" ]; then
    break
  fi
  offset="$next_offset"
done

pigz -f "$output_file"
