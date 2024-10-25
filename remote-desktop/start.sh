#!/bin/bash

set -e

echo "127.0.0.1 $HOSTNAME" >> /etc/hosts

mkdir -p /home/dw-user/Desktop/
cp /org.qgis.qgis.desktop /home/dw-user/Desktop/
cp /gretl.desktop /home/dw-user/Desktop/
chown -R dw-user:dw-user /home/dw-user/Desktop/

touch /home/dw-user/.Xauthority
chown dw-user:dw-user /home/dw-user/.Xauthority

sudo -E -H -u dw-user \
	tigervncserver -SecurityTypes None -xstartup /usr/bin/startlxqt :1

# The webserver for static files that is build into websocketify occasionally
# returns 500s. So we don't use it, and instead serve static files through nginx
nginx -c /nginx.conf

sudo -E -H -u dw-user \
	websockify 8886 localhost:5901
