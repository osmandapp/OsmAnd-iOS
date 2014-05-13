#!/bin/bash

if [ -z "$BASH_VERSION" ]; then
	exec bash "$0" "$@"
	exit $?
fi

# Get root
SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$SRCLOC/.."

# Prepare core dependencies
echo "Configuring dependencies..."
"$ROOT/core/externals/configure.sh" qtbase-ios expat giflib jpeg zlib libpng protobuf skia gdal glm icu4c libarchive
echo "Building dependencies..."
"$ROOT/core/externals/build.sh"

# Prepare iOS dependencies via CocoaPods
POD=`which pod`
if [ -z "$POD" ]; then
	echo "'pod' tool not found, run 'sudo gem install cocoapods'"
	exit 1
fi
$POD update

# Bake or update core projects for XCode
OSMAND_BUILD_TOOL=xcode "$ROOT/build/fat-ios.sh"

# Download all shipped resources
"$SRCLOC/download-shipped-resources.sh"

# Generate resources from SVG
"$SRCLOC/rasterize-resources.sh"
