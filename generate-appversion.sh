#!/bin/bash

# Get version tag string
VERSION_TAG=`(cd $PROJECT_DIR && git describe --long)`
echo "Version tag: $VERSION_TAG"

# Parse version tag string
[[ $VERSION_TAG =~ v([[:digit:]\.]+)([[:alpha:]]?)-([[:digit:]]+)-g([[:xdigit:]]+) ]]
VERSION="${BASH_REMATCH[1]}"
RELEASE="${BASH_REMATCH[2]}"
REVISION="${BASH_REMATCH[3]}"
BUILD="${BASH_REMATCH[4]}"
echo "Version:     $VERSION"
echo "Release:     $RELEASE"
echo "Revision:    $REVISION"
echo "Build:       $BUILD"

# Generate appversion.prefix
APPVERSION_FILE="$BUILD_ROOT/appversion.prefix"
rm -f "$APPVERSION_FILE"
echo "" > "$APPVERSION_FILE"
echo "#define OSMAND_VERSION $VERSION" >> "$APPVERSION_FILE"
echo "#define OSMAND_REVISION $REVISION" >> "$APPVERSION_FILE"
echo "#define OSMAND_RELEASE $RELEASE" >> "$APPVERSION_FILE"
echo "#define OSMAND_BUILD $BUILD" >> "$APPVERSION_FILE"

# Touch plist file
#touch -m "$PROJECT_DIR/$INFOPLIST_FILE"
#touch -A -05 -m "$PROJECT_DIR/$INFOPLIST_FILE"
