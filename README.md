# geocint

###geocint processing pipeline

Directory structure:
 - Makefile - maps dependencies between generation stages
 - data/ - file-based input and output data
 - tables/ - SQL that generates a table named after the script
 - scripts/ - scripts that perform transformation on top of table without creating new one
 - functions / - service SQL functions used in more than a single other file

## scripts/create_geocint_user.sh

`create_geocint_user.sh [username]`

Script for adding user role and schema to geocint database.
If no username is provided, it will be prompted.
User roles are added to the geocint_users group role. You need to add
the following line to pg_hba.conf.

`local   gis    +geocint_users  trust`
