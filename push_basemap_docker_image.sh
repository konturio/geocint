#!/bin/bash
set -e
echo "PLEASE NOTE: you need to docker login with your own credentials into Kontur's nexus to push docker image"
docker build -t nexus.kontur.io:8085/build-basemap . -f dockerfile-basemap
docker push nexus.kontur.io:8085/build-basemap
