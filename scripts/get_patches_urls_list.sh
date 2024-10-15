#!/bin/bash

# Parameters:
# $1 - part of the layer URL (example: "/arcgis/rest/services/COD_External/PHL_pcode/FeatureServer/0")
# $2 - number of records per batch (result_record_count)

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <layer_url> <result_record_count>"
    exit 1
fi

# Base URL for requests
base_url="https://codgis.itos.uga.edu"

# Layer URL part and number of records per batch
layer_url=$1
result_record_count=$2

# Extract the name part of the URL to use in output file names
layer_name=$(echo $layer_url | sed 's/^.\{35\}//' | sed 's#/FeatureServer/.*##')

# Request the total record count for the layer
total_record_count=$(curl -s "${base_url}${layer_url}/query?where=1=1&returnCountOnly=true&f=json" | jq '.count')

# Check for errors during the request
if [ -z "$total_record_count" ] || [ "$total_record_count" -eq 0 ]; then
    echo "Error: Failed to retrieve total record count or no records found."
    exit 1
fi

# Write the layer URL and total record count to layers_feature_count.csv
echo "${base_url}${layer_url},${total_record_count}" >> layers_feature_count.csv

# Generate URLs for each batch of records
result_offset=0
level=$(echo $layer_url | sed 's#.*/FeatureServer/##')  # Extract the layer level (e.g., 0)

while [ "$result_offset" -lt "$total_record_count" ]; do
    next_offset=$((result_offset + result_record_count))
    if [ "$next_offset" -gt "$total_record_count" ]; then
        next_offset=$total_record_count
    fi
    
    # Generate the output file name with range and level
    output_file="${layer_name}_${result_offset}_${next_offset}_level_${level}.geojson"
    
    # Generate the URL and append the output file name
    echo "${base_url}${layer_url}/query?where=1=1&outFields=*&returnGeometry=true&f=json&resultRecordCount=${result_record_count}&resultOffset=${result_offset} ${output_file}"
    
    # Update offset for the next batch
    result_offset=$next_offset
done
