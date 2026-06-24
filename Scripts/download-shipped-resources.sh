#!/bin/bash

if [ -z "$BASH_VERSION" ]; then
	echo "Invalid shell, re-running using bash..."
	exec bash "$0" "$@"
	exit $?
fi
SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ "$(uname -a)" =~ Linux ]]; then
	GET_FILE_MODIFICATION="stat -c %Y"
elif [[ "$(uname -a)" =~ Darwin ]]; then
	GET_FILE_MODIFICATION="stat -f %m"
elif [[ "$(uname -a)" =~ Cygwin ]]; then
	GET_FILE_MODIFICATION="stat -c %Y"
elif [[ "$(uname -a)" =~ MINGW ]]; then
	GET_FILE_MODIFICATION="stat -c %Y"
else
	echo "'$(uname -a)' is not recognized"
	exit 1
fi

# Prepare destination
DEST="$SRCLOC/../Resources/Shipped"
mkdir -p "$DEST"

# Function downloadShippedResource(name, url)
function downloadShippedResource()
{
	local name=$1
	local url=$2
	
	(cd "$DEST" && \
		curl --remote-time --time-cond $name --location --output $name --fail $url && \
		$GET_FILE_MODIFICATION "$name" > "$name.stamp")
	retcode=$?
	if [ $retcode -ne 0 ]; then
		echo "Failed to download '$name' from $url, aborting..."
		exit $retcode
	fi
	echo "Shipping '$name' with version '"$(cat "$DEST/$name.stamp")"'"
}

# Function downloadShippedGzipResource(name, url)
function downloadShippedGzipResource()
{
	local name=$1
	local url=$2
	local compressedName="$name.gz"

	(cd "$DEST" && \
		curl --remote-time --time-cond "$compressedName" --location --output "$compressedName" --fail "$url" && \
		gzip -dc "$compressedName" > "$name" && \
		$GET_FILE_MODIFICATION "$compressedName" > "$name.stamp" && \
		rm "$compressedName")
	retcode=$?
	if [ $retcode -ne 0 ]; then
		echo "Failed to download and unzip '$name' from $url, aborting..."
		exit $retcode
	fi
	echo "Shipping '$name' with version '"$(cat "$DEST/$name.stamp")"'"
}

# Download world mini-basemap
downloadShippedResource WorldMiniBasemap.obf "http://builder.osmand.net/basemap/World_basemap_mini_2.obf"

# Download astronomy stars database
downloadShippedGzipResource stars.db "https://builder.osmand.net/basemap/astro/stars.db.gz"
