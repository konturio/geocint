#!/bin/bash

# pgrouting installation
pg_version="$(psql -V | cut -d " " -f 3 | cut -d "." -f 1)"
sudo apt install -y postgresql-$pg_version-pgrouting
psql -c "create extension pgRouting;"

pip install pandas pyarrow

# It is especially useful to avoid breaking changes (e.g. NumPy 2.x incompatibilities).
# to avoid errors in osgeo compiled wih numpy 1.x
pip install "numpy<2"

# postgresql http binding installation
sudo pgxn install http
sudo apt install -y ansible
sudo apt install -y awscli