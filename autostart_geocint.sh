#!/bin/bash

set -e
PATH="/home/gis/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
cd ~/geocint
git pull
profile_make clean
profile_make -j -k deploy/dev deploy/prod
BRANCH = $(git rev-parse --abbrev-ref HEAD)
if [[ "$BRANCH" = "master" ]];
then
  profile_make -j -k deploy/dev deploy/prod
else
  profile_make -j -k deploy/dev
fi
