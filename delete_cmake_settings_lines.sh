#!/bin/bash

filePathTemplate="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/CLANG_VERSION/include/ia32intrin.h"
cmakeVersion=$( ls /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/ )
filePath=${filePathTemplate/CLANG_VERSION/$cmakeVersion}

sudo sed -i '' 's/#define _bit_scan_forward(A) __bsfd((A))//g' $filePath
sudo sed -i '' 's/#define _bit_scan_reverse(A) __bsrd((A))//g' $filePath