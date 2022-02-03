#!/bin/bash


# NOTE: with current Makefile structure there multiple directory need to be
# persisted across executions.
# I can't wire single persisted volume into multiple paths and I don't won't
# to introduce persisted volume per directory. Also I don't want to change
# Makefile to have single output directory so for now I decided to symlink
# directories that need to be persisted to single volume.
mkdir data
ln -s data /persisted-volume/data
mkdir db
ln -s db /persisted-volume/db
mkdir deploy
ln -s deploy /persisted-volume/deploy

make -j data/basemap.mbtiles
