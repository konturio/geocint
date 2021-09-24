#!/bin/sh
SCRIPT_PATH=$(dirname $0)
PWD=$(pwd)

# Check if profile file exists
if [ ! -f ${SCRIPT_PATH}/../supplemental/OSRM/profiles/$1.lua ]; then
	exit 1
fi;

# Check port number
if [ $2 -lt 1024 -o $2 -gt 65535 ]; then
        exit 1
fi

# Check osm file exists
if [ ! -f "${PWD}/$3" ]; then
        exit 1
fi

PROFILE=$1
PORT=$2
OSM_FILE=$3
NAME=kontur-osrm-backend-by-${PROFILE}

# build docker image
docker build --build-arg PORT=${PORT} --build-arg OSRM_PROFILE=${PROFILE} --build-arg OSM_FILE=${OSM_FILE} --file ${SCRIPT_PATH}/dockerfile-osrm-backend --tag ${NAME} --no-cache ${SCRIPT_PATH}/..
# stop previous container
docker ps -q --filter name=^${NAME}$ | xargs -I'{}' -r docker container stop {}
# remove previous container
docker ps -aq --filter name=^${NAME}$ | xargs -I'{}' -r docker container rm {}
# start docker in new container
docker run -d -p ${PORT}:${PORT} --restart always --name ${NAME} ${NAME}
# clean previous images
docker image prune --force --filter label=name=osrm-builder-by-${PROFILE}
docker image prune --force --filter label=name=osrm-backend-by-${PROFILE}