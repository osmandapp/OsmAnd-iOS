#!/bin/bash

if [ -z "$BASH_VERSION" ]; then
	echo "Invalid shell, re-running using bash..."
	exec bash "$0" "$@"
	exit $?
fi
SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ROOT="$SRCLOC/.."

# Workaround for http://public.kitware.com/Bug/view.php?id=14297
(
	cd "$ROOT/baked/fat-ios-clang.xcode" && \
#	xcodebuild -project OsmAnd_projects.xcodeproj -target ZERO_CHECK -sdk iphoneos -configuration Debug && \
#	xcodebuild -project OsmAnd_projects.xcodeproj -target ZERO_CHECK -sdk iphoneos -configuration Release && \
	xcodebuild -project OsmAnd_projects.xcodeproj -target ZERO_CHECK -sdk iphonesimulator -configuration Debug
#	xcodebuild -project OsmAnd_projects.xcodeproj -target ZERO_CHECK -sdk iphonesimulator -configuration Release \
)

# Build core for all archs
(
	cd "$ROOT/baked/fat-ios-clang.xcode" && \
#	xcodebuild -project OsmAnd_projects.xcodeproj -target OsmAndCore_static_standalone -sdk iphoneos -configuration Debug && \
#	xcodebuild -project OsmAnd_projects.xcodeproj -target OsmAndCore_static_standalone -sdk iphoneos -configuration Release && \
	xcodebuild -project OsmAnd_projects.xcodeproj -target OsmAndCore_static_standalone -sdk iphonesimulator -configuration Debug
#	xcodebuild -project OsmAnd_projects.xcodeproj -target OsmAndCore_static_standalone -sdk iphonesimulator -configuration Release \
)