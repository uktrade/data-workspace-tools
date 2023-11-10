#!/bin/sh

chown -R pgadmin:pgadmin /home/pgadmin

set -e

touch /pgadmin4/.pgpass /pgadmin4/servers.json
chown -R pgadmin:pgadmin \
	/pgadmin4/.pgpass \
	/pgadmin4/servers.json \
	/var/lib/pgadmin \
	/var/log/pgadmin

python3 /usr/local/lib/python3.11/site-packages/pgadmin4/setup.py --load-servers /pgadmin4/servers.json

sudo -E -H -u pgadmin gunicorn --bind 0.0.0.0:8888 --workers=1 --threads=25 --chdir /usr/local/lib/python3.11/site-packages/pgadmin4 pgAdmin4:app
