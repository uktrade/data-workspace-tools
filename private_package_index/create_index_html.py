"""
This file creates a index html file locally with provided .whl file names
so that this can be added to the root of package folder on s3.

python3 create_index_html.py file1.whl file2.whl file3.whl
"""
import sys


def create_index_html(whl_files):
    html_str = (
        "<!DOCTYPE html>"
        + "<html>"
        + "<body>"
        + "".join(
            [
                f'<a href="{filename}">{filename}</a>'
                for filename in whl_files if filename.lower().endswith('.whl')
            ]
        )
        + "</body>"
        + "</html>"
    )
    with open("index.html", "w") as html_file:
        html_file.write(html_str)


whl_files = []
if len(sys.argv) > 1:
    whl_files = sys.argv[1:]
    print("Wheel files list:", whl_files)
    create_index_html(whl_files)
else:
    print("No wheel files found.")
 