#!/usr/bin/env bash

# do not store any other *.tif in input dir
# only *.tif downloaded from OAM
# on total number of *.tif depends this script
# count number of files in input dir ($1)
# get total number of images in oam

currentNumber=$(ls $1 | grep '.tif$' | wc -l)
totalNumber=$(curl --silent https://api.openaerialmap.org/meta | jq '.meta.found')

# count number of new images
# if images more then 1 page(more then 100) - download by pages
# else download only number of images

diff=$(expr $totalNumber - $currentNumber)
if [ $diff -gt 100 ]; then
    diff=$(echo $diff | awk '{print int($0/100)+1}')
    # diff=1
    seq $diff | xargs -I {} curl --silent https://api.openaerialmap.org/meta?page={} | jq -r '.results | .[].uuid' | \
      parallel --progress -j 16 wget -q -P $1 {}
  else
    seq $diff | xargs -I {} curl --silent https://api.openaerialmap.org/meta?limit={} | jq -r '.results | .[].uuid' | \
      parallel --progress -j 16 wget -q -P $1 {}
fi
