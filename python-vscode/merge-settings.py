"""Merges user-settings (saved from previous launches of VS Code) with default settings.

VS Code / code-server doesn't seem to provide a way of having a hierachy of settings, where some
settings are set system-wide by admins. So this file does that - merges user settings with default
settings.

Because of race conditions with s3sync/mobius3, it manually takes the previous settings file from
the user's folder in the bucket, merges it with the default, and re-uploads the merged version to
the bucket.
"""

import os
import json
import sys

import boto3


s3 = boto3.client('s3')

try:
    user_settings = json.loads(s3.get_object(
        Bucket=os.environ["S3_BUCKET"],
        Key=os.environ["S3_PREFIX"] + '.vscode/User/settings.json',
    )['Body'].read())
except KeyError:
    print("Missing S3_BUCKET or S3_PREFIX environment variable. Skipping fetching user settings since probably running locally.")
    user_settings = {}
except json.JSONDecodeError:
    user_settings = {}
except s3.exceptions.NoSuchKey:
    user_settings = {}

with open('/etc/code-server-defaults/settings.json', 'rb') as f:
    default_settings = json.loads(f.read())

merged_settings = json.dumps({
    **user_settings,
    **default_settings,
}).encode('utf-8')

os.makedirs('/home/dw-user/.vscode/User')
with open('/home/dw-user/.vscode/User/settings.json', 'wb') as f:
    f.write(merged_settings)

try:
    s3.put_object(
        Body=merged_settings,
        Bucket=os.environ["S3_BUCKET"],
        Key=os.environ["S3_PREFIX"] + '.vscode/User/settings.json',
    )
except KeyError:
    print("Missing S3_BUCKET or S3_PREFIX environment variable. Skipping putting user settings since probably running locally.")
