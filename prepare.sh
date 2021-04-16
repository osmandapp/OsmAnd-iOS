#!/bin/bash -xe

SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Prepare iOS dependencies via CocoaPods
"$SRCLOC/Scripts/install_pods.sh"

# Bake or update core projects for XCode
OSMAND_BUILD_TOOL=xcode "$SRCLOC/../build/fat-ios.sh"

# Download all shipped resources
"$SRCLOC/Scripts/download-shipped-resources.sh"
