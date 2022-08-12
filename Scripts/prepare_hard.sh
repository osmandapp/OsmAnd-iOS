#!/bin/bash

sudo clear
echo "    iOS project reset and prepare - START."

cd `dirname $0`
SCRIPTS_DIR=$(pwd)
cd ..
IOS_DIR=$(pwd)
cd ..
REPOSITORIES_DIR=$(pwd)

# echo "Updating all repositories:"
# cd $IOS_DIR
# 
# git pull
# # git checkout master && git pull origin master
# cd ../android && git checkout master && git pull origin master 
# cd ../build && git checkout master && git pull origin master 
# cd ../core && git checkout master && git pull origin master 
# cd ../core-legacy && git checkout master && git pull origin master 
# cd ../resources && git checkout master && git pull origin master 
# cd ../help && git checkout master && git pull origin master

# Xcode -> Product -> Clean build folder
echo "    XCode Clean build folder:"
cd $IOS_DIR
xcodebuild clean -workspace OsmAnd.xcworkspace -scheme "OsmAnd Maps"

echo "    Cleaning all pods"
cd $IOS_DIR
rm -rf Pods/ || true
rm -rf Podfile.lock || true

echo "    Deletiing build folders:"
cd $REPOSITORIES_DIR
sudo rm -R baked/fat-ios-clang.xcode
sudo rm -R binaries/ios.clang-iphoneos
sudo rm -R binaries/ios.clang-iphonesimulator
sudo rm -R binaries/ios.clang-maccatalyst
sudo rm -R ~/Library/Developer/Xcode/DerivedData/*

echo "    Prepare environment:"
cd $SCRIPTS_DIR
./delete_cmake_settings_lines.sh

echo "    Redownloading dependencies:"
cd $IOS_DIR
./prepare.sh

echo "    iOS project reset and prepare - DONE."
