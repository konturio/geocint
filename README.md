# geocint

## geocint processing pipeline

Geocint is Kontur's geodata ETL/CI/CD pipeline designed for ease of maintenance and high single-node throughput. Writing
the code as Geocint target makes sure that it is fully recorded, can be run autonomously, can be inspected, reviewed and
tested by other team members, and will automatically produce new artifacts once new input data comes in.

### Technology stack is:

- Huge bare metal machine. High CPU count, high memory, large industrial SSD. All further stack is tuned for this
  specific machine, not some abstract one. OS is latest Ubuntu version (not necessarily LTS).
- Bash (linux shell) for scripting one-liners that get data into the database for further processing, or get data out of
  the database for deployment. https://tldp.org/LDP/abs/html/
- GNU Make as job server. We do not use advanced features like variables and wildcards, using simple explicit
  "file-depends-on-file" mode. Make takes care of running different jobs concurrently whenever possible.
  https://makefiletutorial.com/
- make-profiler is used as linter and preprocessor for Make that outputs network diagram of what is getting built when
  and why. The output chart allows to see what went wrong and quickly get to logs.
  https://github.com/konturio/make-profiler
- Postgres (latest stable) for data manipulation. No replication, minimal WAL logging, disabled synchronous_commit
  (fsync enabled!), parallel costs tuned to prefer parallel execution whenever possible. To facilitate debugging
  auto_explain is enabled, you can find slow query plans in postgresql's log files. When you need to make it faster,
  follow https://postgrespro.ru/education/courses/QPT
- GNU Parallel for paralleling tasks that cannot be effectively paralleled by Postgres, essentially parallel-enabled
  Bash. https://www.gnu.org/software/parallel/parallel.html
- PostGIS (latest unreleased master) for geodata manipulation. Kontur has maintainers for PostGIS in team so you can
  develop or ask for features directly. https://postgis.net/docs/manual-dev/reference.html
- h3_pg for hexagon grid manipulation, https://github.com/bytesandbrains/h3-pg. When googling for manuals make sure you
  use this specific extension.
- aws-cli is used to deploy data into s3 buckets or get inputs from there. https://docs.aws.amazon.com/cli/index.html
- python3 for small tasks like unpivoting source data.
- GDAL, OGR, osm-c-tools, osmium, and others are used as needed in Bash CLI.

### Things to avoid:

- Complex python scripts should become less complex bash+sql scripts.
- Java services are out of scope of geocint.

### Directory and files structure:

- autostart_geocint.sh - script, that runs the pipeline: prod/dev division, cleaning targets and posting info messages
- [Makefile](Makefile) - maps dependencies between generation stages
- basemap/ - scripts and styles for basemap production
- functions/ - service SQL functions, used in more than a single other file
- procedures/ - service SQL procedures, used in more than a single other file
- scripts/ - scripts that perform transformation on top of table without creating new one
- supplemental/ - additional files (OSRM profiles)
- tables/ - SQL that generates a table named after the script
- tile_generator/ - a service that produces vector tiles
- data/ - file-based input and output data
    - data/in - all input data, downloaded elsewhere
    - data/in/raster - all downloaded geotiffs
    - data/mid - all intermediate data (retiles, unpacks, reprojections and etc) which can removed after each launch
    - data/out - all generated final data (tiles, dumps, unloading for the clients and etc)

### Slack messages

The geocint pipeline should send messages to the Slack channel. Create channel with name `geocint`, generate Slack token
and store it in the `SLACK_KEY` variable in file `$HOME/.profile`.

```shell
export SLACK_KEY=<your_key>
```

### scripts/create_geocint_user.sh

`create_geocint_user.sh [username]`

Script for adding user role and schema to geocint database. If no username is provided, it will be prompted. User roles
are added to the geocint_users group role. You need to add the following line to pg_hba.conf.

`local   gis +geocint_users  trust`
