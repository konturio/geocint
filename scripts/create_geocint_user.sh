#!/bin/sh
PSQL_SELECT='psql -t -A -U gis -c'
PSQL_COMMAND='psql -q -U gis -c'

username=$(whoami)

printf 'Enter password for [%s]: ' "${username}"
stty -echo
read -r password
stty echo
echo

if [ -z "${password}" ]; then
  echo "Empty string is not a valid password"
  exit 1
fi

if [ -z "$(${PSQL_SELECT} "SELECT to_regrole('geocint_users');")" ]; then
  echo "Create group role geocint_users"
  ${PSQL_COMMAND} "
    CREATE ROLE geocint_users;
    GRANT pg_monitor TO geocint_users;
    GRANT pg_signal_backend TO geocint_users;
  "
fi

if [ -z "$(${PSQL_SELECT} "SELECT to_regrole('${username}');")" ]; then
  echo "Create login role ${username}"
  ${PSQL_COMMAND} "
    CREATE ROLE ${username} WITH LOGIN PASSWORD '${password}';
    GRANT geocint_users TO ${username};
  "
fi

if [ -z "$(${PSQL_SELECT} "SELECT to_regnamespace('${username}');")" ]; then
  echo "Creating user schema ${username}"
  ${PSQL_COMMAND} "
    CREATE SCHEMA ${username} AUTHORIZATION ${username};
  "
fi
