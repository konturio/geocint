#!/bin/bash

set -e
PATH="/home/gis/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
cd ~/geocint
git pull
profile_make clean
branch="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$branch" = "master" ]];
then
  echo "Current branch is $branch. Running dev and prod targets."
  profile_make -j -k dev prod
else
  echo "Current branch is $branch (not master). Running dev target."
  profile_make -j -k dev
fi
