#!/bin/bash

if [ -z "$BASH_VERSION" ]; then
	exec bash "$0" "$@"
	exit $?
fi

# Get root
SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$SRCLOC/.."

# Build core for all archs
(cd "$ROOT/baked/fat-ios-clang.xcode" && \
	xcodebuild -project OsmAnd_projects.xcodeproj -target OsmAndCore_static -sdk iphoneos -configuration Debug && \
	xcodebuild -project OsmAnd_projects.xcodeproj -target OsmAndCore_static -sdk iphoneos -configuration Release && \
	xcodebuild -project OsmAnd_projects.xcodeproj -target OsmAndCore_static -sdk iphonesimulator -configuration Debug && \
	xcodebuild -project OsmAnd_projects.xcodeproj -target OsmAndCore_static -sdk iphonesimulator -configuration Release)
