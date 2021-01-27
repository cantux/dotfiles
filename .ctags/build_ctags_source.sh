#!/bin/bash

# This script configures and builds universal ctags


git clone https://github.com/universal-ctags/ctags.git ctags_source

SRC_DIR=ctags_source
DIST_DIR=$(pwd)/uctags_bin

pushd $SRC_DIR
./autogen.sh

./configure --prefix=$DIST_DIR 

make
make install
popd

