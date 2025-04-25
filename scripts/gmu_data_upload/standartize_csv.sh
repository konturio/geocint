#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 <input.csv>"
  exit 1
fi

input="$1"
output="std_$(basename "$input")"

if [ ! -f "$input" ]; then
  echo "File not found: $input"
  exit 2
fi

tail -n +2 "$input" | awk -F',' '{print $1 "," $2}' > "$output"
