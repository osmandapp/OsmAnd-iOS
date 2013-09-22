#!/bin/bash

SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ -z "$OSMAND_BUILD_CPU_CORES_NUM" ]]; then
	OSMAND_BUILD_CPU_CORES_NUM=`sysctl hw.ncpu | awk '{print $2}'`
fi

# Prepare core dependencies
DEPS=expat gdal giflib glm glsl-optimizer jpeg libpng protobuf qtbase-ios skia zlib
"$SRCLOC/core/externals/configure.sh" $DEPS
"$SRCLOC/core/externals/build.sh" $DEPS

# Build core library with different flavours
("$SRCLOC/build/simulator-ios.sh" debug && (cd "$SRCLOC/baked/simulator-ios-clang-debug.makefile" && make -j$OSMAND_BUILD_CPU_CORES_NUM OsmAndCore_static))
("$SRCLOC/build/simulator-ios.sh" release && (cd "$SRCLOC/baked/simulator-ios-clang-release.makefile" && make -j$OSMAND_BUILD_CPU_CORES_NUM OsmAndCore_static))
("$SRCLOC/build/device-ios.sh" debug && (cd "$SRCLOC/baked/device-ios-clang-debug.makefile" && make -j$OSMAND_BUILD_CPU_CORES_NUM OsmAndCore_static))
("$SRCLOC/build/device-ios.sh" release && (cd "$SRCLOC/baked/device-ios-clang-release.makefile" && make -j$OSMAND_BUILD_CPU_CORES_NUM OsmAndCore_static))
