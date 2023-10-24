#!/bin/sh

set -e

touch /pgadmin4/.pgpass /pgadmin4/servers.json
chown -R pgadmin \
	/pgadmin4/config_distro.py \
	/pgadmin4/.pgpass \
	/pgadmin4/servers.json \
	/var/lib/pgadmin

sudo -E -H -u pgadmin /entrypoint.sh
