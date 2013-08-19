#!/bin/bash

SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

OSMAND_EXTERNALS_SET=($*)
if [ -z "$OSMAND_EXTERNALS_SET" ]; then
	OSMAND_EXTERNALS_SET=*
fi

for external in ${OSMAND_EXTERNALS_SET[@]/#/$SRCLOC/} ; do
	if ls -1 $external/upstream.* >/dev/null 2>&1
	then
		echo "Cleaning '"$(basename "$external")"'..."
		rm -rf $external/upstream.*
	fi
done