#!/bin/bash

set -e
PATH="/home/gis/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
cd ~/geocint

# On Sunday, force checkout master branch
test $(date +'%w') "=" 0 && git checkout -f master

# Install / upgrade the python libs
sudo pip3 install slackclient
sudo pip3 install https://github.com/konturio/make-profiler/archive/master.zip
sudo pip3 install pandas

# Pull and stash uncommitted changes from Git
git rebase --autostash
git pull

profile_make clean

branch="$(git rev-parse --abbrev-ref HEAD)"
slack_message=$(python3 scripts/slack_message.py geocint "Nightly build" cat)

if [[ "$branch" == "master" ]]; then
  echo "Current branch is $branch. Running dev and prod targets." | $slack_message
  profile_make -j -k dev prod
  make -k -q -n --debug=b dev prod 2>&1 | grep -v Trying | grep -v Rejecting | grep -v implicit | grep -v "Looking for" | grep -v "Successfully remade" | tail -n+10 | SLACK_KEY=xoxb-2329653303-1423278364594-PNV6Urmf55CEvKxpK2UiqjIG $slack_message
  # Notification about pipeline status at channel
  if [[ -e $(find /home/gis/geocint/ -maxdepth 1 -type f -name "prod" -mmin -10) ]]; then
    echo "$branch has built successfully! prod target exists." | $slack_message
  else
    echo "$branch has failed! prod target doesn't exist!" | $slack_message
  fi
else
  echo "Current branch is $branch (not master). Running dev target." | $slack_message
  profile_make -j -k dev
  make -k -q -n --debug=b dev 2>&1 | grep -v Trying | grep -v Rejecting | grep -v implicit | grep -v "Looking for" | grep -v "Successfully remade" | tail -n+10 | SLACK_KEY=xoxb-2329653303-1423278364594-PNV6Urmf55CEvKxpK2UiqjIG $slack_message
  if [[ -e $(find /home/gis/geocint/ -maxdepth 1 -type f -name "dev" -mmin -10) ]]; then
    echo "$branch has built successfully! dev target exists." | $slack_message
  else
    echo "$branch has failed! dev target doesn't exist!" | $slack_message
  fi
fi

# redraw the make.svg after build
profile_make
