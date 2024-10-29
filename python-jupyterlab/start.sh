#!/bin/sh

# When on EFS, we expect to not be able to change ownership, and we don't need to
chown -R dw-user:dw-user /home/dw-user

set -e

# Java programs can error if $HOSTNAME is not resolvable
echo "127.0.0.1 $HOSTNAME" >> /etc/hosts

exec sudo -E -H -u dw-user jupyter \
	lab \
	--config=/etc/jupyter/jupyter_notebook_config.py \
	--NotebookApp.token='' \
	--NotebookApp.ip='0.0.0.0' \
	--NotebookApp.allow_remote_access=True \
	--NotebookApp.port=8888
