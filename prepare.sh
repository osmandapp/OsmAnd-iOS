#!/bin/bash -xe

SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# it only works if absolute path of prebuilt / makefiles is the same
if [ "$DOWNLOAD_PREBUILT_QT_FILES" == "true" ] ; then
	# FILE_TO_DOWNLOAD=${BUILT_QT_FILES_ZIPFILE:-qt-ios-prebuilt.zip}
	FILE_TO_DOWNLOAD=qt_download.zip
	wget https://builder.osmand.net/binaries/ios/qt-ios-prebuilt.zip -O "$FILE_TO_DOWNLOAD"
	FILE_TO_DOWNLOADEDIR=$(basename $FILE_TO_DOWNLOAD).dir
	unzip -o -d $FILE_TO_DOWNLOADEDIR "$FILE_TO_DOWNLOAD"
	(cd $FILE_TO_DOWNLOADEDIR && mv upstream.patched* $SRCLOC/../core/externals/qtbase-ios/)
	(cd $FILE_TO_DOWNLOADEDIR && mv .stamp $SRCLOC/../core/externals/qtbase-ios/)
	rm -rf $FILE_TO_DOWNLOADEDIR
fi

# Bake or update core projects for XCode
OSMAND_BUILD_TOOL=xcode "$SRCLOC/../build/fat-ios.sh"

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

# Fetch translation from Android.
# Only if script running with "--sync_translations" parameter ($ ...prepare.sh --sync_translations)
if [[ "$1" == --sync_translations ]]; then
  "$SRCLOC/Scripts/add_translations.swift"
fi