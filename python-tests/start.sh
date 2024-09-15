#!/bin/sh

# When on EFS, we expect to not be able to change ownership, and we don't need to
chown -R python-tests:python-tests /home/python-tests

set -e

# Java programs can error if $HOSTNAME is not resolvable
echo "127.0.0.1 $HOSTNAME" >> /etc/hosts

# What else do we need to do here?