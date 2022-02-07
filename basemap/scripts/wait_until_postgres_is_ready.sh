#!/bin/bash

max_retry=120
counter=0
until pg_isready -U gis
do
   sleep 1
   [[ counter -eq $max_retry ]] && echo "Failed!" && exit 1
   echo "Trying to connect to postgres again. Try #$counter"
   ((counter++))
done

exit 0
