#!/bin/sh

# When on EFS, we expect to not be able to change ownership, and we don't need to
chown -R dw-user:dw-user /home/dw-user

set -e

# Java programs can error if $HOSTNAME is not resolvable
echo "127.0.0.1 $HOSTNAME" >> /etc/hosts

cd /root
exec sudo -E -H -u dw-user yarn theia start /home/dw-user \
	--hostname=0.0.0.0 \
	--port=8888 \
	--cache-folder=/tmp/.yarn-cache
