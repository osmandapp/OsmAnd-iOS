#!/bin/bash -xe

# With the release of Xcode 15.3, a compatibility issue with version of the libxslt library has arisen. Previously, version 1.1.29 was used. Now, the compatible version is 1.1.34. The script will replace the source code of libxslt with the compatible one from the 'BRCybertron' pod, which will then be linked as a static library.

# We get the absolute path to the directory containing the script
SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

parent_dir="$(dirname "$SRCLOC")"

# Directory paths
source_dir="$parent_dir/BRCybertronRecources"
destination_dir="$parent_dir/Pods/BRCybertron/libxslt"

rm -rf "$source_dir/"

function download
{
    local from=$1
    local to=$2
    echo "Downloading $from to $to"
    i="0"
    local exitCode=0
    sleep 10
    while [ $i -lt 3 ]
    do
        curl -L --fail "$from" > "$to"
        exitCode=$?
        if [ $exitCode -ne 0 ]; then    
            echo "Download $from failed $i"
            sleep 30
        else 
            return 0
        fi
        i=$[$i+1]
    done
    if [ $exitCode -ne 0 ]; then    
        echo "Download $from failed"
        exit $exitCode
    fi
}

mkdir -p "$source_dir/"

download "https://creator.osmand.net/dependencies-mirror/libxslt-1.1.34.tar.xz" "$source_dir/libxslt-1.1.34.tar.xz"

# source_dir
echo "source_dir archive..."
tar -xf "$source_dir/libxslt-1.1.34.tar.xz" -C "$source_dir"

if [ $? -ne 0 ]; then
    echo "Error: Failed to unzip archive."
    exit 1
fi

echo "The archive was successfully unzipped to $source_dir."

# Checking the presence of directories
if [ ! -d "$source_dir/libxslt-1.1.34/libexslt" ] || [ ! -d "$source_dir/libxslt-1.1.34/libxslt" ]; then
    echo "Error: The libexslt and/or libxslt folders were not found in $source_dir"
    exit 1
fi

# Copy folders to the destination folder with replacement
cp -Rf "$source_dir/libxslt-1.1.34/libxslt" "$destination_dir"
cp -Rf "$source_dir/libxslt-1.1.34/libexslt" "$destination_dir"

echo "The libexslt and libxslt folders were successfully copied and replaced in $destination_dir"

rm -rf "$source_dir/"

