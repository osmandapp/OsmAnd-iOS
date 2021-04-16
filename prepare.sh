#!/bin/bash -xe

SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ "$DOWNLOAD_PREBUILT_QT_FILES" == "true" ] ; then
	# FILE_TO_DOWNLOAD=${BUILT_QT_FILES_ZIPFILE:-qt-ios-prebuilt.zip}
	FILE_TO_DOWNLOAD=qt_download.zip
	wget https://builder.osmand.net/binaries/ios/qt-ios-prebuilt.zip -O "$FILE_TO_DOWNLOAD"
	TMPDIR=$(basename $FILE_TO_DOWNLOAD).dir
	unzip -o -d $TMPDIR "$FILE_TO_DOWNLOAD"
	(cd $TMPDIR && mv upstream.patched* $SRCLOC/../core/externals/qtbase-ios/)
	(cd $TMPDIR && mv .stamp $SRCLOC/../core/externals/qtbase-ios/)
	rm -rf $TMPDIR
fi

# Bake or update core projects for XCode
OSMAND_BUILD_TOOL=xcode NOT_BUILD_QT_IOS_IF_PRESENT=true "$SRCLOC/../build/fat-ios.sh"

# Package built qt files as zip file
if [ ! -z "$BUILT_QT_FILES_ZIPFILE" ] && [ ! "$DOWNLOAD_PREBUILT_QT_FILES" == "true" ]; then
	BNAME=$(basename $BUILT_QT_FILES_ZIPFILE)
	( cd $SRCLOC/../core/externals/qtbase-ios/ && zip --symlinks -r "$BNAME" . )
	mv $SRCLOC/../core/externals/qtbase-ios/$BNAME $BUILT_QT_FILES_ZIPFILE
fi

# Prepare iOS dependencies via CocoaPods
"$SRCLOC/Scripts/install_pods.sh"

# Download all shipped resources
"$SRCLOC/Scripts/download-shipped-resources.sh"
