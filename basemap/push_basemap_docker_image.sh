#!/bin/bash
set -e
echo "PLEASE NOTE: you need to docker login with your own credentials into Kontur's nexus to push docker image"
ln -s ../tile_generator ./tile_generator
docker build -t nexus.kontur.io:8085/konturdev/build-basemap . -f dockerfile-basemap
docker push nexus.kontur.io:8085/konturdev/build-basemap

