#!/bin/bash

SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$SRCLOC/.."

if [[ -z "$OSMAND_BUILD_CPU_CORES_NUM" ]]; then
	OSMAND_BUILD_CPU_CORES_NUM=`sysctl hw.ncpu | awk '{print $2}'`
fi

# Prepare core dependencies
echo "Configuring dependencies..."
"$ROOT/core/externals/configure.sh" qtbase-ios expat harfbuzz freetype giflib jpeg zlib libpng protobuf skia gdal glsl-optimizer glm
echo "Building dependencies..."
"$ROOT/core/externals/build.sh"

# Build core library with different flavours
if [ ! -d "$ROOT/baked/simulator-ios-clang-debug.makefile" ]; then
	"$ROOT/build/simulator-ios.sh" debug
fi
(cd "$ROOT/baked/simulator-ios-clang-debug.makefile" && make -j$OSMAND_BUILD_CPU_CORES_NUM OsmAndCore_static)

if [ ! -d "$ROOT/baked/simulator-ios-clang-release.makefile" ]; then
	"$ROOT/build/simulator-ios.sh" release
fi
(cd "$ROOT/baked/simulator-ios-clang-release.makefile" && make -j$OSMAND_BUILD_CPU_CORES_NUM OsmAndCore_static)

if [ ! -d "$ROOT/baked/device-ios-clang-debug.makefile" ]; then
	"$ROOT/build/device-ios.sh" debug
fi
(cd "$ROOT/baked/device-ios-clang-debug.makefile" && make -j$OSMAND_BUILD_CPU_CORES_NUM OsmAndCore_static)

if [ ! -d "$ROOT/baked/device-ios-clang-release.makefile" ]; then
	"$ROOT/build/device-ios.sh" release
fi
(cd "$ROOT/baked/device-ios-clang-release.makefile" && make -j$OSMAND_BUILD_CPU_CORES_NUM OsmAndCore_static)
