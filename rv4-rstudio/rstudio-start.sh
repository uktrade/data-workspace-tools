#!/bin/bash

mkdir -p /etc/rstudio/connections

# When on EFS, we expect to not be able to change ownership, and we don't need to
chown -R dw-user:dw-user /home/dw-user

set -e

# A previous version of this script wrote environment variables to this file,
# which was synced between container starts. Deleting to ensure we don't
# incorrectly use old values
rm -f /home/dw-user/.Renviron

while IFS='=' read -r name value ; do
  if [[ $name == *'DATABASE_DSN__'* ]]; then
    # Make available as environment variable
    echo "${name}='${!name}'" >> /etc/R/Renviron.site

    # Make available as connection in the UI
    conn_name=$(echo ${name}    | sed -E 's/DATABASE_DSN__(.*)/\1/')
    db_user=$(echo ${!name}     | sed -E 's/.*user=([a-z0-9_]+).*/\1/')
    db_password=$(echo ${!name} | sed -E 's/.*password=([a-zA-Z0-9_]+).*/\1/')
    db_port=$(echo ${!name}     | sed -E 's/.*port=([0-9]+).*/\1/')
    db_name=$(echo ${!name}     | sed -E 's/.*name=([a-z0-9_-]+).*/\1/')
    db_host=$(echo ${!name}     | sed -E 's/.*host=([a-z0-9_\.-]+).*/\1/')

    echo "library(DBI)" > "/etc/rstudio/connections/$conn_name.R"
    echo "con <- dbConnect(RPostgreSQL::PostgreSQL(), user='${db_user}', password='$db_password', host='$db_host', port='$db_port', dbname='$db_name')" >> "/etc/rstudio/connections/$conn_name.R"
  fi

  # Make all S3_* environment variables available. This is dynamic based
  # on which teams the user is a part of
  if [[ $name == *'S3_'* ]]; then
    echo "${name}='${!name}'" >> /etc/R/Renviron.site
  fi
done < <(env)

echo "APP_SCHEMA='${APP_SCHEMA}'" >> /etc/R/Renviron.site
echo "AWS_DEFAULT_REGION='${AWS_DEFAULT_REGION}'" >> /etc/R/Renviron.site
echo "AWS_CONTAINER_CREDENTIALS_RELATIVE_URI='${AWS_CONTAINER_CREDENTIALS_RELATIVE_URI}'" >> /etc/R/Renviron.site
echo "TZ='Europe/London'" >> /etc/R/Renviron.site
echo "PGHOST='${PGHOST}'" >> /etc/R/Renviron.site
echo "PGPORT='${PGPORT}'" >> /etc/R/Renviron.site
echo "PGSSLMODE='${PGSSLMODE}'" >> /etc/R/Renviron.site
echo "PGDATABASE='${PGDATABASE}'" >> /etc/R/Renviron.site
echo "PGUSER='${PGUSER}'" >> /etc/R/Renviron.site
echo "PGPASSWORD='${PGPASSWORD}'" >> /etc/R/Renviron.site

exec /usr/lib/rstudio-server/bin/rserver --server-daemonize=0 --server-user=dw-user
