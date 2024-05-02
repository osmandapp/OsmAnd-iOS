#!/bin/bash -xe

SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# it only works if absolute path of prebuilt / makefiles is the same
if [ "$DOWNLOAD_PREBUILT_QT_FILES" == "true" ] ; then
	# FILE_TO_DOWNLOAD=${BUILT_QT_FILES_ZIPFILE:-qt-ios-prebuilt.zip}
	FILE_TO_DOWNLOAD=qt_download.zip
	wget https://creator.osmand.net/binaries/ios/qt-ios-prebuilt.zip -O "$FILE_TO_DOWNLOAD"
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

# Getting the Xcode version
xcode_version=$(xcodebuild -version | grep "Xcode")

# Using awk to extract only the Xcode version number
xcode_version_number=$(echo "$xcode_version" | awk '{print $2}')

# Comparing the version with 15.3
if (( $(echo "$xcode_version_number >= 15.3" | bc -l) )); then
    echo "Xcode version $xcode_version_number greater than or equal to 15.3"
	# The script will replace the source code of libxslt with the compatible one from the 'BRCybertron' pod
	"$SRCLOC/Scripts/change_libxslt_resources_for_BRCybertron_pod.sh"
else
    echo "Xcode version $xcode_version_number less than 15.3"
fi

# Download all shipped resources
"$SRCLOC/Scripts/download-shipped-resources.sh"

# Fetch translation from Android.
# Only if script running with "--sync_translations" parameter ($ ...prepare.sh --sync_translations)
if [[ "$1" == --sync_translations ]]; then
  "$SRCLOC/Scripts/add_translations.swift"
fi