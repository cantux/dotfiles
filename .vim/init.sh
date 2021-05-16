#!/bin/bash

cp plugged/**/colors/* colors/.

pushd plugged/YouCompleteMe
python install.py --all
popd
