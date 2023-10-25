#!/bin/sh

set -e

# Typically, we use set the owner of files/folders (not in the home directory)
# in the Dockerfile. However, we've changed the ID of the pgadmin user,
# and changing to the same owner but a different ID doesn't seem to get
# properly saved when done from the Dockerfile. So, we do it here.
touch /pgpass /pgadmin4/servers.json
chmod 600 /pgpass
chown -R pgadmin:root \
	/pgadmin4/config_distro.py \
	/pgpass \
	/pgadmin4/servers.json \
	/var/lib/pgadmin

sudo -E -H -u pgadmin /entrypoint.sh
