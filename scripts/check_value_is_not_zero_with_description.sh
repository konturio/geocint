#!/bin/bash
# input $1 parameter is string with comma, eg "layer,12034"
# current_indicator is part before comma
# current_value is part after comma
current_indicator=$(echo "$1" | cut -d "," -f1)
current_value=$(echo "$1" | cut -d "," -f2)
# checks if number  ($current_value parameter) is equal to 0
if [[ "$current_value" -ne 0 ]] ; then
  echo "$current_indicator: Returned count is not 0 ($current_value), test passed"; exit 0
else
  echo "$current_indicator: Returned count is 0! Take your attention!"; exit 1;
fi
