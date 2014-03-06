#!/bin/bash

if [ -z "$BASH_VERSION" ]; then
	exec bash "$0" "$@"
	exit $?
fi

SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

OSMAND_EXTERNALS_SET=($*)
if [ -z "$OSMAND_EXTERNALS_SET" ]; then
	OSMAND_EXTERNALS_SET=*
fi

last_stamp=""
if [ -f "$SRCLOC/.stamp" ]; then
	last_stamp=`cat "$SRCLOC/.stamp"`
fi
current_stamp=`cat "$SRCLOC/stamp"`
echo "Last stamp:    "$last_stamp
echo "Current stamp: "$current_stamp
if [ "$last_stamp" != "$current_stamp" ]; then
	echo "Stamps differ, will clean externals..."
	"$SRCLOC/clean.sh"
	cp "$SRCLOC/stamp" "$SRCLOC/.stamp"
fi

for external in ${OSMAND_EXTERNALS_SET[@]/#/$SRCLOC/} ; do
	if [ -d "$external" ]; then
		if [ -e "$external/configure.sh" ]; then
			$external/configure.sh
		fi
	fi
done