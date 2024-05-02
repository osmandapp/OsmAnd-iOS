#!/bin/bash -xe

# With the release of Xcode 15.3, a compatibility issue with version of the libxslt library has arisen. Previously, version 1.1.29 was used. Now, the compatible version is 1.1.31. The script will replace the source code of libxslt with the compatible one from the 'BRCybertron' pod, which will then be linked as a static library.

# We get the absolute path to the directory containing the script
SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

parent_dir="$(dirname "$SRCLOC")"

# Directory paths
source_dir="$parent_dir/BRCybertronRecources"
destination_dir="$parent_dir/Pods/BRCybertron/libxslt"

# Checking the presence of directories
if [ ! -d "$source_dir/libexslt" ] || [ ! -d "$source_dir/libxslt" ]; then
    echo "Error: The libexslt and/or libxslt folders were not found in $source_dir"
    exit 1
fi

# Copy folders to the destination folder with replacement
cp -Rf "$source_dir/libexslt" "$destination_dir"
cp -Rf "$source_dir/libxslt" "$destination_dir"

echo "The libexslt and libxslt folders were successfully copied and replaced in $destination_dir"
