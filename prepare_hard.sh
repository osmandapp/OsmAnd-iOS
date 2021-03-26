#!/bin/bash

sudo clear
echo "iOS project reset and prepare - START."

echo "    Updating all repositories:"
cd `dirname $0`
git pull origin master && cd ../android && git pull origin master && cd ../resources && git pull origin master && cd ../core && git pull origin master && cd ../core-legacy && git pull origin legacy_core && cd ../help && git pull origin master

cd ..
echo "    Deletiing build folders:"
sudo rm -R baked
sudo rm -R binaries
sudo rm -R ~/Library/Developer/Xcode/DerivedData/*

echo "    Redownloading dependencies:"
./ios/delete_cmake_settings_lines.sh
./ios/prepare.sh

echo "iOS project reset and prepare - DONE."