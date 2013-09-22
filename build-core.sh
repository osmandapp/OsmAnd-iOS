#!/bin/bash

SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$SRCLOC/.."

if [[ -z "$OSMAND_BUILD_CPU_CORES_NUM" ]]; then
	OSMAND_BUILD_CPU_CORES_NUM=`sysctl hw.ncpu | awk '{print $2}'`
fi

# Prepare core dependencies
DEPS="expat gdal giflib glm glsl-optimizer jpeg libpng protobuf qtbase-ios skia zlib"
"$ROOT/core/externals/configure.sh" $DEPS
"$ROOT/core/externals/build.sh" $DEPS

# Build core library with different flavours
("$ROOT/build/simulator-ios.sh" debug && (cd "$ROOT/baked/simulator-ios-clang-debug.makefile" && make -j$OSMAND_BUILD_CPU_CORES_NUM OsmAndCore_static))
("$ROOT/build/simulator-ios.sh" release && (cd "$ROOT/baked/simulator-ios-clang-release.makefile" && make -j$OSMAND_BUILD_CPU_CORES_NUM OsmAndCore_static))
("$ROOT/build/device-ios.sh" debug && (cd "$ROOT/baked/device-ios-clang-debug.makefile" && make -j$OSMAND_BUILD_CPU_CORES_NUM OsmAndCore_static))
("$ROOT/build/device-ios.sh" release && (cd "$ROOT/baked/device-ios-clang-release.makefile" && make -j$OSMAND_BUILD_CPU_CORES_NUM OsmAndCore_static))
