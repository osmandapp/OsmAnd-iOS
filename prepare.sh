#!/bin/bash

if [ -z "$BASH_VERSION" ]; then
	echo "Invalid shell, re-running using bash..."
	exec bash "$0" "$@"
	exit $?
fi
SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ROOT="$SRCLOC/.."

# Prepare iOS dependencies via CocoaPods
POD=`which pod`
if [ -z "$POD" ]; then
	echo "'pod' tool not found, run 'sudo gem install cocoapods'"
	exit 1
fi
if [[ ! -f "$SRCLOC/Podfile.lock" ]]; then
	echo "Installing dependencies via CocoaPods"
	(cd "$SRCLOC" && $POD install)
else
	echo "Updating dependencies via CocoaPods"
	(cd "$SRCLOC" && $POD update)
fi
retcode=$?
if [ $retcode -ne 0 ]; then
	echo "Failed to processing dependencies via CocoaPods, aborting..."
	exit $retcode
fi

# Bake or update core projects for XCode
OSMAND_BUILD_TOOL=xcode "$ROOT/build/fat-ios.sh"
retcode=$?
if [ $retcode -ne 0 ]; then
	echo "Failed to generate project for XCode, aborting..."
	exit $retcode
fi

# Download all shipped resources
"$SRCLOC/download-shipped-resources.sh"
retcode=$?
if [ $retcode -ne 0 ]; then
	echo "Failed to download shipped resources, aborting..."
	exit $retcode
fi

# Generate resources from SVG
"$SRCLOC/rasterize-resources.sh"
retcode=$?
if [ $retcode -ne 0 ]; then
	echo "Failed to rasterize resources, aborting..."
	exit $retcode
fi
