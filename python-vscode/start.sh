#!/bin/sh

# When on EFS, we expect to not be able to change ownership, and we don't need to
chown -R dw-user:dw-user /home/dw-user

set -e

# Java programs can error if $HOSTNAME is not resolvable
echo "127.0.0.1 $HOSTNAME" >> /etc/hosts

python /merge-settings.py

chown -R dw-user:dw-user /home/dw-user/.vscode
chown -R dw-user:dw-user /etc/code-server-extensions

cd /home/dw-user
exec sudo -E -H -u dw-user code-server --log trace --extensions-dir /etc/code-server-extensions --user-data-dir /home/dw-user/.vscode --auth none --bind-addr 0.0.0.0:8888
