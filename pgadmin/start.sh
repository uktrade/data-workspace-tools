#!/bin/sh

chown -R dw-user:dw-user /home/dw-user

set -e

touch /pgadmin4/.pgpass /pgadmin4/servers.json
chown -R dw-user:dw-user \
	/pgadmin4/.pgpass \
	/pgadmin4/servers.json \
	/var/lib/pgadmin \
	/var/log/pgadmin

python3 /usr/local/lib/python3.9/dist-packages/pgadmin4/setup.py load-servers /pgadmin4/servers.json

exec sudo -E -H -u dw-user gunicorn --bind 0.0.0.0:8888 --workers=1 --threads=25 --chdir /usr/local/lib/python3.9/dist-packages/pgadmin4 pgAdmin4:app
