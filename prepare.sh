#!/bin/bash -xe

SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Prepare iOS dependencies via CocoaPods
"$SRCLOC/Scripts/install_pods.sh"

# Bake or update core projects for XCode
OSMAND_BUILD_TOOL=xcode "$SRCLOC/../build/fat-ios.sh"
if [ ! -z "$BUILT_QT_FILES_ZIPFILE" ]; then
	TMP_DIR=$(basename $BUILT_QT_FILES_ZIPFILE).dir
	mkdir -p $TMP_DIR
	cp -r $SRCLOC/../core/externals/qtbase-ios/upstream.patched* $TMP_DIR/
	zip -r  "$BUILT_QT_FILES_ZIPFILE" "$TMP_DIR/*"
fi

# Download all shipped resources
"$SRCLOC/Scripts/download-shipped-resources.sh"
