#!/usr/bin/env bash
set -e

# When on EFS, we expect to not be able to change ownership, and we don't need to
chown -R dw-user:dw-user /home/dw-user

# Start the database
#
if [ -z "${POSTGRES_USER}" ] || [ -z "${POSTGRES_PASSWORD}" ] \
  || [ -z "${POSTGRES_HOST}" ] || [ -z "${POSTGRES_PORT}" ] \
  || [ -z "${POSTGRES_DB}" ]
then
  echo "Starting inbuilt database"
  ./mathesar/db-run.sh
  export POSTGRES_USER=postgres
  export POSTGRES_PASSWORD=mathesar
  export POSTGRES_HOST=localhost
  export POSTGRES_PORT=5432
  export POSTGRES_DB=mathesar_django
  export PGSSLMODE=disable
fi

cd mathesar

python3 -m mathesar.install
# Start the Django server on port 8888. Add debug log level to gunicorn when appropriate.
PYTHONPATH=/app gunicorn config.wsgi -b 0.0.0.0:8888 $([ "$DEBUG" = "true" ] && echo -n "--log-level=debug") && fg

exec parallel --will-cite --line-buffer --jobs 2 --halt now,done=1 ::: \
    "PYTHONPATH=/app gunicorn config.wsgi -b 0.0.0.0:8888 $([ "$DEBUG" = "true" ] && echo -n "--log-level=debug") && fg" \
    "caddy run --config Caddyfile --adapter caddyfile"
