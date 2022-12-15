#!/bin/bash

cleanup() {
  rm -f make.lock
}

# Install / upgrade the python libs
sudo pip3 install slackclient
sudo pip3 install https://github.com/konturio/make-profiler/archive/master.zip
sudo pip3 install pandas
sudo pip3 install hdx-python-api

# Terminate script after failed command execution
set -e
PATH="/home/gis/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/usr/local/go/bin"

# add event-api credentials to env
set -a
. ~/.event-api/credentials
set +a

cd ~/geocint

echo "Geocint pipeline is starting nightly build!" | python3 scripts/slack_message.py geocint "Night build" cat

# make.lock is a file which exists while pipeline running
# if make.lock exists, pipeline should not be started
if [ -e make.lock ]; then
  echo "Skip start: running pipeline is not done yet." | python3 scripts/slack_message.py geocint "Nightly build" cat
  exit 1
fi

touch make.lock
trap 'cleanup' EXIT

# On Sunday, force checkout master branch
# test $(date +'%w') "=" 0 && git checkout -f master

# Pull and stash uncommitted changes from Git
git pull --rebase --autostash || { git stash && git pull && echo 'git rebase autostash failed, stash and pull executed' | python3 scripts/slack_message.py geocint "Nightly build" cat; }

profile_make clean

# Check name of current git branch
branch="$(git rev-parse --abbrev-ref HEAD)"
host_name="$(hostname)"

if [[ "$host_name" == "geocint" ]]; then
  echo "Geocint server: current branch is $branch. Running prod targets." | python3 scripts/slack_message.py geocint "Nightly build" cat
  profile_make -j -k prod
  make -k -q -n --debug=b prod 2>&1 | grep -v Trying | grep -v Rejecting | grep -v implicit | grep -v "Looking for" | grep -v "Successfully remade" | tail -n+10 | python3 scripts/slack_message.py geocint "Nightly build" cat
else
  echo "Mustang server: current branch is $branch. Running dev target." | python3 scripts/slack_message.py geocint "Nightly build" racehorse
  profile_make -j -k dev
  make -k -q -n --debug=b dev 2>&1 | grep -v Trying | grep -v Rejecting | grep -v implicit | grep -v "Looking for" | grep -v "Successfully remade" | tail -n+10 | python3 scripts/slack_message.py geocint "Nightly build" racehorse
fi

# redraw the make.svg after build
profile_make
