#!/bin/bash
TOOLCHAIN=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
CLANG_VERSION=$(ls $TOOLCHAIN/usr/lib/clang/)
sudo patch $TOOLCHAIN/usr/lib/clang/$CLANG_VERSION/include/ia32intrin.h ../.github/workflows/__bsfd.patch 
