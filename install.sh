#!/bin/bash

# pgrouting installation
pg_version="$(psql -V | cut -d " " -f 3 | cut -d "." -f 1)"
sudo apt install -y postgresql-$pg_version-pgrouting

# postgresql http binding installation
sudo pgxn install http