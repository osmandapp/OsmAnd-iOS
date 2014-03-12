#!/bin/bash

if [ -z "$BASH_VERSION" ]; then
	exec bash "$0" "$@"
	exit $?
fi

# Get root
SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$SRCLOC/.."

# Download world mini-basemap
mkdir -p "$SRCLOC/ShippedResources"
(cd "$SRCLOC/ShippedResources" && \
	curl -z WorldMiniBasemap.obf -L http://builder.osmand.net:81/basemap/World_basemap_mini_2.obf -o WorldMiniBasemap.obf)
