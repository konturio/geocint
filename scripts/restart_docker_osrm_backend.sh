#!/bin/sh

# Check port number
if [ $2 -lt 1024 -o $2 -gt 65535 ]; then
        exit 1
fi

NAME=$1
PORT=$2

# Stop previous container
docker ps -q --filter name=^${NAME}$ | xargs -I'{}' -r docker container stop {}
# Remove previous container
docker ps -aq --filter name=^${NAME}$ | xargs -I'{}' -r docker container rm {}
# Start docker in new container
docker run -d -p ${PORT}:${PORT} --restart always --name ${NAME} ${NAME}
