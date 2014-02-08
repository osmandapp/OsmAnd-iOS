#!/bin/bash

# Prepare core dependencies
echo "Configuring dependencies..."
"$ROOT/core/externals/configure.sh" qtbase-ios expat giflib jpeg zlib libpng protobuf skia gdal glsl-optimizer glm
echo "Building dependencies..."
"$ROOT/core/externals/build.sh"

# Build core projects for XCode
if [ ! -d "$ROOT/baked/fat-ios-clang.xcode" ]; then
	OSMAND_BUILD_TOOL=xcode "$ROOT/build/fat-ios.sh"
fi
