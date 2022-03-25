#!/bin/bash

cleanup() {
# since kubernetes consider job done after all containers
# are exit. postgres which is running in another container
# also need to be killed. it is possible to just kill it by name
# because `shareProcessNamespace` is enabled.
  pkill postgres
}

set -e

# NOTE: with current Makefile structure there multiple output directories
# need to be persisted across executions.
# I can't wire single persisted volume into multiple paths and I don't won't
# to introduce persisted volume per directory. Also I don't want to change
# Makefile to have single output directory so for now I decided to symlink
# directories that need to be persisted to single volume.
mkdir -p /persisted-volume/data
ln -s /persisted-volume/data data
mkdir -p /persisted-volume/db
ln -s /persisted-volume/db db
mkdir -p /persisted-volume/deploy
ln -s /persisted-volume/deploy deploy

trap 'cleanup' EXIT

# wait until postgres which is running in another container will be ready
bash scripts/wait_until_postgres_is_ready.sh
make basemap_all
make clean
