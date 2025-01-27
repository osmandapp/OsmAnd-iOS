#!/bin/bash
SRCLOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SRCLOC/../../core/externals/qtbase-ios/
./link_qt_for_arm_device.sh
