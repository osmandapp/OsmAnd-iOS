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
"$ROOT/core/externals/configure.sh" qtbase-ios expat giflib jpeg zlib libpng protobuf skia gdal glsl-optimizer glm icu4c
echo "Building dependencies..."
"$ROOT/core/externals/build.sh"

# Bake or update core projects for XCode
OSMAND_BUILD_TOOL=xcode "$ROOT/build/fat-ios.sh"

# Download all shipped resources
"$SRCLOC/download-shipped-resources.sh"

# Generate resources from SVG
"$SRCLOC/rasterize-resources.sh"
