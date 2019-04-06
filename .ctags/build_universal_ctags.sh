#!/bin/bash

# This script configures and builds universal ctags

SRC_DIR=universal_ctags_source
DIST_DIR=$(pwd)/uctags_bin

pushd $SRC_DIR
./autogen.sh

./configure --prefix=$DIST_DIR 

make
make install
popd

