#!/bin/bash

# Terminate script after failed command execution
set -e
PATH="/home/gis/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
cd ~/geocint

if [ -e make.lock ]; then
  echo "Skip start: running pipeline is not done yet." | python3 scripts/slack_message.py geocint "Nightly build" cat
  exit 1
else
  touch make.lock
fi

# On Sunday, force checkout master branch
test $(date +'%w') "=" 0 && git checkout -f master

# Install / upgrade the python libs
sudo pip3 install slackclient
sudo pip3 install https://github.com/konturio/make-profiler/archive/master.zip
sudo pip3 install pandas

# Pull and stash uncommitted changes from Git
git pull --rebase --autostash

profile_make clean

# Check name of current git branch
branch="$(git rev-parse --abbrev-ref HEAD)"

if [[ "$branch" == "master" ]]; then
  echo "Current branch is $branch. Running dev and prod targets." | python3 scripts/slack_message.py geocint "Nightly build" cat
  profile_make -j -k dev prod
  make -k -q -n --debug=b dev prod 2>&1 | grep -v Trying | grep -v Rejecting | grep -v implicit | grep -v "Looking for" | grep -v "Successfully remade" | tail -n+10 | python3 scripts/slack_message.py geocint "Nightly build" cat
else
  echo "Current branch is $branch (not master). Running dev target." | python3 scripts/slack_message.py geocint "Nightly build" cat
  profile_make -j -k dev
  make -k -q -n --debug=b dev 2>&1 | grep -v Trying | grep -v Rejecting | grep -v implicit | grep -v "Looking for" | grep -v "Successfully remade" | tail -n+10 | python3 scripts/slack_message.py geocint "Nightly build" cat
fi

# redraw the make.svg after build
profile_make
