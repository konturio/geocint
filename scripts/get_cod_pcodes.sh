#!/bin/bash

# $1 - feature layer url

# Prepare inputs
api_url="$1"

output_file=$2
failed_list=$3
stop=false

echo $output_file

rm -rf $output_file

# Initialize output file with FeatureCollection structure
echo '{ "type": "FeatureCollection", "features": [' > $output_file

# first_chunk=true

# Execute the request and save the HTTP status code
response=$(curl -w "HTTPSTATUS:%{http_code}" -H "Cache-Control: no-cache, max-age=0" "$api_url")

# Split the response and the HTTP status code
body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
http_status=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

# Check HTTP status code
if [ "$http_status" -ne 200 ]; then
    echo "Error: HTTP request failed with status code $http_status"
    echo "Response body: $body"
    echo "$1 $2" >> $failed_list
    rm -rf $output_file
    exit 1
fi

# Check if the response contains an error from the API
if echo "$body" | jq -e .error >/dev/null; then
    error_message=$(echo "$body" | jq -r '.error.message')
    echo "Error: API returned an error: $error_message"
    echo "$1 $2" >> $failed_list
    rm -rf $output_file
    exit 1
fi

echo "$body" | jq -c '.features[] | {type: "Feature", properties: .attributes, geometry: {type: "Polygon", coordinates: .geometry.rings}}' >> $output_file
    
# add comma between features, to make geojson valid
sed -i '3,$s/^/,/; $!s/^,/,/' $output_file

# close FeatureCollection structure in output file
echo ']}' >> $output_file
