#!/bin/sh

# When on EFS, we expect to not be able to change ownership, and we don't need to
chown -R dw-user:dw-user /home/s3sync/data

set -e

# Disable for testing
while true; do sleep 2; done

# Path-style even though it's deprecated. The bucket names have dots in, and
# at the time of writing the host-style certs returned by AWS are wildcards
# and don't support dots in the bucket name
# Excluding .checkpoints from remote to not have issues with jupyters3
# .checkpoints folders that are subfolders of files in S3. Other dot files
# already on the remote _are_ synced to local
# Exclude .__mobius3_flush__ files locally, since there is a suspected bug
# in mobius3 where they can end up being uploaded
# Excluding various config and cache files/folders for remote desktop. The most crucial of these
# seems to be the .Xauthority file which must not get deleted, otherwise the remote desktop
# will refuse to open any new windows
sudo -E -u dw-user mobius3 \
    /home/s3sync/data \
    ${S3_BUCKET} \
    https://s3-${S3_REGION}.amazonaws.com/{}/ \
    ${S3_REGION} \
    --prefix ${S3_PREFIX} \
    --cloudwatch-monitoring-endpoint=https://monitoring.${CLOUDWATCH_MONITORING_REGION}.amazonaws.com/ \
    --cloudwatch-monitoring-region=${CLOUDWATCH_MONITORING_REGION} \
    --cloudwatch-monitoring-namespace=${CLOUDWATCH_MONITORING_NAMESPACE} \
    --log-level INFO \
    --credentials-source ecs-container-endpoint \
    --exclude-remote '(.*(/|^)\.checkpoints/)|(.*(/|^)bigdata/.*)|(.*(/|^)\.vnc/?.*)|(.*(/|^)\.dbus/?.*)|(.*(/|^)\.config/lxqt?.*)|(.*(/|^)\.cache/openbox?.*)|(.*(/|^)\.config/openbox?.*)|(.*(/|^)\.cache/mesa_shader_cache?.*)|(.*(/|^)\.Xauthority)|(.*(/|^)Desktop/.*\.desktop$)|(.*(/|^)vscode\.lock$)' \
    --exclude-local '(.*(/|^)\.__mobius3_flush__.*)|(.*(/|^)bigdata/.*)|(.*(/|^)\.vnc/?.*)|(.*(/|^)\.dbus/?.*)|(.*(/|^)\.config/lxqt?.*)|(.*(/|^)\.cache/openbox?.*)|(.*(/|^)\.config/openbox?.*)|(.*(/|^)\.cache/mesa_shader_cache?.*)|(.*(/|^)\.Xauthority)|(.*(/|^)Desktop/.*\.desktop$)|(.*(/|^)vscode\.lock$)' \
    --upload-on-create '^.*/\.git/.*$' \
    --force-ipv4
