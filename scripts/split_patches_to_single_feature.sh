#!/bin/bash

# Split big patches to single features and generate pairs download url + output file for each feature

# Parameters:
# $1 - input URL (example: "https://codgis.itos.uga.edu/arcgis/rest/services/COD_External/PHL_pcode/FeatureServer/2/query?where=1=1&outFields=*&returnGeometry=true&f=json&resultRecordCount=500&resultOffset=0")
# $2 - output file name (example: "PHL_pcode_0_88_level_2.geojson")

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <url> <output_file>"
    exit 1
fi

# Extract the lower and upper bounds from the output file name
output_file=$2
lower_bound=$(echo $output_file | sed 's/.*_\([0-9]\+\)_\([0-9]\+\)_.*.geojson/\1/')
upper_bound=$(echo $output_file | sed 's/.*_\([0-9]\+\)_\([0-9]\+\)_.*.geojson/\2/')

# Ensure that the extracted bounds are numeric
if ! [[ "$lower_bound" =~ ^[0-9]+$ ]] || ! [[ "$upper_bound" =~ ^[0-9]+$ ]]; then
    echo "Error: Could not extract numeric bounds from the output file name."
    exit 1
fi

# Extract the base URL before the parameters
base_url=$(echo "$1" | sed 's/resultRecordCount=[0-9]\+&resultOffset=[0-9]\+//')

# Generate URLs for each feature and corresponding output file names
for ((i=lower_bound; i<upper_bound; i++)); do
    # Generate URL for a single feature (adjust resultRecordCount to 1 and use resultOffset for the feature index)
    single_feature_url="${base_url}resultRecordCount=1&resultOffset=${i}"
    
    # Generate corresponding output file name
    single_feature_file=$(echo $output_file | sed "s/_${lower_bound}_${upper_bound}_/_${i}_${i}_/")
    
    # Output the URL and the corresponding file name
    echo "$single_feature_url $single_feature_file"
done
