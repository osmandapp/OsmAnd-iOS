#!/bin/bash
SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
POD=`which pod`
if [ -z "$POD" ]; then
	echo "'pod' tool not found, run 'sudo gem install cocoapods'"
	exit 1
fi
if [[ ! -f "$SRCLOC/Podfile.lock" ]]; then
	echo "Installing dependencies via CocoaPods"
	(cd "$SRCLOC"/.. && $POD install)
else
	echo "Updating dependencies via CocoaPods"
	(cd "$SRCLOC"/.. && $POD update)
fi
retcode=$?
if [ $retcode -ne 0 ]; then
	echo "Failed to processing dependencies via CocoaPods, aborting..."
	exit $retcode
fi
