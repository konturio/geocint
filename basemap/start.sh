#!/bin/bash

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

make clean
make basemap_all
