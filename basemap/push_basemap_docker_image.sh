#!/bin/bash
set -e
echo "PLEASE NOTE: you need to docker login with your own credentials into Kontur's nexus to push docker image"
# NOTE: tile_genrator is used by both: main and basemap pipelines but
# I don't won't to include parent directory into docker build context
# so I decided to symlink tile_generator into basemap directory for now
ln -s ../tile_generator ./tile_generator
docker build -t nexus.kontur.io:8085/konturdev/build-basemap . -f dockerfile-basemap
docker push nexus.kontur.io:8085/konturdev/build-basemap

