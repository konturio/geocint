#!/bin/bash 

set -e

cd ~/geocint; git pull
profile_make clean
profile_make -j -k all