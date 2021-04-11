#!/bin/bash

set -e
PATH="/home/gis/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
cd ~/geocint

# On Sunday, force checkout master branch
test `date +'%w'` "=" 0 && git checkout -f master

git pull
profile_make clean
branch="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$branch" = "master" ]];
then
  echo "Current branch is $branch. Running dev and prod targets." | python3 scripts/slack_message.py geocint "Nightly build" cat
  profile_make -j -k dev prod
  make -k -q -n --debug=b dev prod 2>&1 |grep -v Trying | grep -v Rejecting | grep -v implicit | grep -v "Looking for" | grep -v "Successfully remade" |tail -n+10 | SLACK_KEY=xoxb-2329653303-1423278364594-PNV6Urmf55CEvKxpK2UiqjIG python3 scripts/slack_message.py geocint "Nightly build" cat
else
  echo "Current branch is $branch (not master). Running dev target." | python3 scripts/slack_message.py geocint "Nightly build" cat
  profile_make -j -k dev
  make -k -q -n --debug=b dev 2>&1 |grep -v Trying | grep -v Rejecting | grep -v implicit | grep -v "Looking for" | grep -v "Successfully remade" |tail -n+10 | SLACK_KEY=xoxb-2329653303-1423278364594-PNV6Urmf55CEvKxpK2UiqjIG python3 scripts/slack_message.py geocint "Nightly build" cat
fi
