#!/bin/bash

sudo clear
echo "iOS project reset and prepare - START."

echo "Cleaning all pods"
rm -rf Pods/ || true
rm -rf Podfile.lock || true

echo "Updating all repositories:"
cd `dirname $0`

git pull
# git checkout master && git pull origin master
cd ../android && git checkout master && git pull origin master 
cd ../build && git checkout master && git pull origin master 
cd ../core && git checkout master && git pull origin master 
cd ../core-legacy && git checkout master && git pull origin master 
cd ../resources && git checkout master && git pull origin master 
cd ../help && git checkout master && git pull origin master

echo "    Deletiing build folders:"
cd `dirname $0`
cd ..
sudo rm -R baked
sudo rm -R binaries
sudo rm -R ~/Library/Developer/Xcode/DerivedData/*

echo "    Prepare environment:"
cd `dirname $0`
./delete_cmake_settings_lines.sh

echo "    Redownloading dependencies:"
cd `dirname $0`
./prepare.sh

echo "iOS project reset and prepare - DONE."
