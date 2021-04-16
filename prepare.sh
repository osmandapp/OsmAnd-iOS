#!/bin/bash -xe

SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Prepare iOS dependencies via CocoaPods
"$SRCLOC/Scripts/install_pods.sh"

if [ "$DOWNLOAD_PREBUILT_QT_FILES" = true ] ; then
	BUILT_QT_FILES_ZIPFILE=${BUILT_QT_FILES_ZIPFILE:-qt-ios-prebuilt.zip}
	wget https://builder.osmand.net/binaries/ios/qt-ios-prebuilt.zip -O "$BUILT_QT_FILES_ZIPFILE"
	unzip -o -d $SRCLOC/../core/externals/qtbase-ios/ "$BUILT_QT_FILES_ZIPFILE"
fi

# Bake or update core projects for XCode
OSMAND_BUILD_TOOL=xcode "$SRCLOC/../build/fat-ios.sh"

# Package built qt files as zip file
if [ ! -z "$BUILT_QT_FILES_ZIPFILE" ] && [ ! -f "$BUILT_QT_FILES_ZIPFILE" ]; then
	TMP_DIR=$(basename $BUILT_QT_FILES_ZIPFILE).dir
	mkdir -p $TMP_DIR
	cp -r $SRCLOC/../core/externals/qtbase-ios/upstream.patched* $TMP_DIR/
	( cd "$TMP_DIR"/ && zip -r "$TMP_DIR.zip" . )
	mv $TMP_DIR/$TMP_DIR.zip $BUILT_QT_FILES_ZIPFILE
	rm -rf $TMP_DIR/
fi

# Download all shipped resources
"$SRCLOC/Scripts/download-shipped-resources.sh"
