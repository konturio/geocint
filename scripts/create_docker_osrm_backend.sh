#!/bin/sh
SCRIPT_PATH=$(dirname $0)
PWD=$(pwd)

# Check if profile file exists
if [ ! -f ${SCRIPT_PATH}/../supplemental/OSRM/profiles/$1.lua ]; then
        echo error profile
        exit 1
fi;

# Check port number
if [ $2 -lt 0 -o $2 -gt 65535 ]; then
        echo error port
        exit 1
fi

# Check osm data file exists
if [ ! -f "${PWD}/$3" ]; then
        echo error osm
        exit 1
fi

PROFILE=$1
PORT=$2
OSM_DATA=$3

# build docker image
docker build --build-arg PORT=${PORT} --build-arg OSRM_PROFILE=${PROFILE} --build-arg OSM_DATA=${OSM_DATA} --file ${SCRIPT_PATH}/dockerfile-osrm-backend --tag kontur-osrm-backend-by-${PROFILE} --no-cache ${SCRIPT_PATH}/..
# stop previous container
docker ps -q --filter "name=^kontur-osrm-backend-by-${PROFILE}$$" | xargs -I'{}' -r docker container stop {}
# remove previous container
docker ps -aq --filter "name=^kontur-osrm-backend-by-${PROFILE}$$" | xargs -I'{}' -r docker container rm {}
# start docker in new container
docker run -d -p ${PORT}:${PORT} --restart always --name kontur-osrm-backend-by-${PROFILE} kontur-osrm-backend-by-${PROFILE}
# clean previous images
docker image prune --force --filter label=name=osrm-builder-${PROFILE}
docker image prune --force --filter label=name=osrm-backend-${PROFILE}