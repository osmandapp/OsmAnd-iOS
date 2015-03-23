#!/bin/bash

if [ -z "$BASH_VERSION" ]; then
	echo "Invalid shell, re-running using bash..."
	exec bash "$0" "$@"
	exit $?
fi
SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

BUNDLE_ID="$1"

echo "Changing bundle identifier to '$BUNDLE_ID'"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
