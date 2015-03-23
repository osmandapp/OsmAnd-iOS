#!/bin/bash

if [ -z "$BASH_VERSION" ]; then
	echo "Invalid shell, re-running using bash..."
	exec bash "$0" "$@"
	exit $?
fi
SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get version tag/hash strings
IOS_GIT_TAG=`(cd "$PROJECT_DIR" && git describe --long)`
echo "iOS git tag: $IOS_GIT_TAG"
CORE_GIT_HASH=`(cd "$PROJECT_DIR/../core" && git log --pretty=format:'%h' -n 1)`
echo "Core git hash: $CORE_GIT_HASH"
RESOURCES_GIT_HASH=`(cd "$PROJECT_DIR/../resources" && git log --pretty=format:'%h' -n 1)`
echo "Resources git hash: $RESOURCES_GIT_HASH"

# Parse version tag string
[[ $IOS_GIT_TAG =~ v([[:digit:]\.]+)([[:alpha:]]?)-([[:digit:]]+)-g([[:xdigit:]]+) ]]
VERSION="${BASH_REMATCH[1]}"
RELEASE="${BASH_REMATCH[2]}"
REVISION="${BASH_REMATCH[3]}"
BUILD="$VERSION.$REVISION$RELEASE"
HASH="${BASH_REMATCH[4]}_${CORE_GIT_HASH}_${RESOURCES_GIT_HASH}"
echo "Version: $VERSION.$REVISION$RELEASE ($BUILD)"
echo "Hash: $HASH"

# Embed version into plist file
OSMAND_VERSION="$VERSION.$REVISION$RELEASE"
OSMAND_BUILD_HASH="$HASH"
echo "Embedding version in plist file: '${TARGET_BUILD_DIR}/${INFOPLIST_PATH}'"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $OSMAND_VERSION" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $OSMAND_VERSION" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
/usr/libexec/PlistBuddy -c "Set :OSMAND_BUILD $OSMAND_BUILD_HASH" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
