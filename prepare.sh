#!/bin/bash -xe

SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Remove legacy CocoaPods artifacts before rebuilding dependencies.
rm -rf "$SRCLOC/Pods" "$SRCLOC/Podfile.lock"

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

# Fetch prebuilt ANGLE frameworks, unless they are already here.
# They are only used by the Simulator build (OSMAND_USE_ANGLE is defined for the
# iphonesimulator SDK only): the Simulator serves native OpenGL ES through a software
# rasteriser, so the map runs at roughly 1 fps, while ANGLE routes the same calls to Metal,
# which the Simulator does accelerate. Device builds use EAGL and never load these.
# Not fatal if it fails - only Simulator rendering depends on it.
if [ ! -d "$SRCLOC/libEGL.xcframework" ] || [ ! -d "$SRCLOC/libGLESv2.xcframework" ]; then
	echo "Downloading prebuilt ANGLE frameworks"
	ANGLE_ZIP="$SRCLOC/angle_download.zip"
	if wget -q https://builder.osmand.net/binaries/ios/angle-ios-prebuilt.zip -O "$ANGLE_ZIP"; then
		unzip -o -q -d "$SRCLOC" "$ANGLE_ZIP"
		rm -f "$ANGLE_ZIP"
	else
		rm -f "$ANGLE_ZIP"
		echo "WARNING: could not fetch ANGLE frameworks - the Simulator build will not link."
		echo "         Device builds are unaffected."
	fi
fi

# Bake or update core projects for XCode
OSMAND_BUILD_TOOL=xcode "$SRCLOC/../build/fat-ios.sh"

# Package built qt files as zip file
if [ ! -z "$BUILT_QT_FILES_ZIPFILE" ] && [ ! "$DOWNLOAD_PREBUILT_QT_FILES" == "true" ]; then
	BNAME=$(basename $BUILT_QT_FILES_ZIPFILE)
	( cd $SRCLOC/../core/externals/qtbase-ios/ && zip --symlinks -r "$BNAME" . )
	mv $SRCLOC/../core/externals/qtbase-ios/$BNAME $BUILT_QT_FILES_ZIPFILE
fi

# Download BRCybertron libxslt sources used by the local Swift package.
"$SRCLOC/Scripts/download_libxslt_for_BRCybertron_spm.sh"

# Download all shipped resources
"$SRCLOC/Scripts/download-shipped-resources.sh"

# Fetch translation from Android.
# Only if script running with "--sync_translations" parameter ($ ...prepare.sh --sync_translations)
if [[ "$1" == --sync_translations ]]; then
  "$SRCLOC/Scripts/add_translations.swift"
fi
