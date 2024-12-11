"""
This file creates a html index file out of whl files available given path
and uploads it to the root of package folder on s3.

python3 create_index_html.py s3://jupyter.notebook.uktrade.io/shared/ddat_packages/pypi/dwutils
"""
import boto3
import re
import sys

S3_BUCKET_NAME_REGEX = re.compile(r"^[a-z0-9-]{3,63}$")

def is_s3_path(s3_path):
    if not s3_path.startswith("s3://"):
        print("doesn't start with s3://")
        return False
    s3_path = s3_path[5:]
    parts = s3_path.split("/", 1)
    if len(parts) < 2:
        print("not enough parts in the path")
        return False

    # bucket_name = parts[0]
    # if not S3_BUCKET_NAME_REGEX.match(bucket_name):
    #     print("failed regex check")
    #     return False

    print("all good with the path")
    return True

def split_s3_path(s3_path):
    s3_path = s3_path[5:]
    parts = s3_path.split("/", 1)
    return parts[0], parts[1]

def get_wheel_filenames(s3, bucket, prefix):
    filenames_and_paths = []
    result = s3.list_objects_v2(Bucket=bucket, Prefix=prefix)
    print(result)
    if 'Contents' in result:
        for item in result["Contents"]:
            file = item["Key"]
            if file.lower().endswith(".whl"):
                filename = file.split('/')[-1]
                filenames_and_paths.append((filename, file))
    if len(filenames_and_paths) == 0:
        raise ValueError("no whl files found")
    return filenames_and_paths

def create_and_upload_index_html(s3, bucket, prefix, whl_files):
    html_str = (
        "<!DOCTYPE html>"
        + "<html>"
        + "<body>"
        + "".join(
            [
                f'<a href="{filename[1]}">{filename[0]}</a>'
                for filename in whl_files
            ]
        )
        + "</body>"
        + "</html>"
    )
    s3.put_object(
        Body=html_str,
        Bucket=bucket,
        ContentType="text/html",
        Key=prefix
    )
    print("upload finished")

if len(sys.argv) <= 1:
    print("No s3 path found.")

s3_client = boto3.client("s3", region_name="eu-west-2")
s3_path = sys.argv[1]
if not is_s3_path(s3_path):
    raise ValueError("not valid s3 path")
bucket, prefix = split_s3_path(s3_path)
print(f"looking for whl files in {bucket} with prefix {prefix}")
whl_files = get_wheel_filenames(s3_client, bucket, prefix)
print("whl files found:", whl_files)
print("creating and uploading index")
create_and_upload_index_html(s3_client, bucket, prefix, whl_files)
print("index upload finished!")
