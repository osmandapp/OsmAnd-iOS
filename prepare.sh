#!/bin/bash -xe

SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Prepare iOS dependencies via CocoaPods
"$SRCLOC/Scripts/install_pods.sh"

if [ "$DOWNLOAD_PREBUILT_QT_FILES" = true ] ; then
	BUILT_QT_FILES_ZIPFILE=${BUILT_QT_FILES_ZIPFILE:-qt-ios-prebuilt.zip}
	wget https://builder.osmand.net/binaries/ios/qt-ios-prebuilt.zip -O "$BUILT_QT_FILES_ZIPFILE"
	TMPDIR=$(basename $BUILT_QT_FILES_ZIPFILE).dir
	unzip -o -d $TMPDIR "$BUILT_QT_FILES_ZIPFILE"
	mv $TMPDIR/upstream.patched* $SRCLOC/../core/externals/qtbase-ios/
	rm -rf $TMPDIR
fi

# Bake or update core projects for XCode
OSMAND_BUILD_TOOL=xcode "$SRCLOC/../build/fat-ios.sh"

# Package built qt files as zip file
if [ ! -z "$BUILT_QT_FILES_ZIPFILE" ] && [ ! -f "$BUILT_QT_FILES_ZIPFILE" ]; then
	BNAME=$(basename $BUILT_QT_FILES_ZIPFILE)
	( cd $SRCLOC/../core/externals/qtbase-ios/ && zip --symlinks -r "$BNAME" . )
	mv $SRCLOC/../core/externals/qtbase-ios/$BNAME $BUILT_QT_FILES_ZIPFILE
fi

# Download all shipped resources
"$SRCLOC/Scripts/download-shipped-resources.sh"