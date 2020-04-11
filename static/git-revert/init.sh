#!/usr/bin/env bash
set -e

SCRIPT_PATH=`dirname $0`
cd $SCRIPT_PATH


rm -rf $SCRIPT_PATH/repository
mkdir $SCRIPT_PATH/repository

pushd $SCRIPT_PATH/repository

git init

touch file.txt

echo "G1" >> file.txt; git add file.txt; git commit -m "G1"

echo "G2" >> file.txt; git add file.txt; git commit -m "G2"

echo "G3" >> file.txt; git add file.txt; git commit -m "G3"

echo "B1" >> file.txt; git add file.txt; git commit -m "B1"

echo "B2" >> file.txt; git add file.txt; git commit -m "B2"

echo "B3" >> file.txt; git add file.txt; git commit -m "B3"

popd
