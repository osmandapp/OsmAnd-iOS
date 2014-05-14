#!/bin/bash

if [ -z "$BASH_VERSION" ]; then
	exec bash "$0" "$@"
	exit $?
fi

# Get root
SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$SRCLOC/.."

# Fail on any error
set -e

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
DEST="$SRCLOC/Resources/Shipped"
mkdir -p "$DEST"

# Download world mini-basemap
(cd "$DEST" && \
	curl -R -z WorldMiniBasemap.obf -L http://builder.osmand.net:81/basemap/World_basemap_mini_2.obf -o WorldMiniBasemap.obf && \
	$GET_FILE_MODIFICATION "$DEST/WorldMiniBasemap.obf" > "$DEST/WorldMiniBasemap.obf.stamp")
echo "Shipping 'WorldMiniBasemap.obf' with version '$(cat $DEST/WorldMiniBasemap.obf.stamp)'"
