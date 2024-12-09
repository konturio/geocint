#!/bin/bash

# Check if the target name is provided as an argument
if [[ -z "$1" ]]; then
    echo "Usage: $0 <target_name>"
    exit 1
fi

TARGET_NAME="$1"

# Search for files matching the target name, calculate average time, sort, and display the results
echo "List of files and average execution time for target: $TARGET_NAME"
FILES=$(find /home/gis/geocint/logs -type f -regex ".*/${TARGET_NAME}/log.txt" -mtime -50 \
    -printf "%T+ %p; " \
    -exec awk '/Time:/ {sum += $4} END {print sum/60000 " min"}' '{}' \; | sort)

if [[ -z "$FILES" ]]; then
    echo "No files found for target: $TARGET_NAME"
    exit 1
fi

echo "$FILES"

# Extract the path of the most recent file
LATEST_FILE=$(echo "$FILES" | tail -1 | awk -F';' '{print $1}' | awk '{print $2}')

# Check if a file was found and display its contents
if [[ -n "$LATEST_FILE" && -f "$LATEST_FILE" ]]; then
    echo -e "\nContents of the most recent file ($LATEST_FILE):"
    cat "$LATEST_FILE"
else
    echo -e "\nError: No valid file found to display contents."
fi
