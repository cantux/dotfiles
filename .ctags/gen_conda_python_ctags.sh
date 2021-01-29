#!/bin/bash

set -x

echo "Building ctags under this directory: ${PWD}"
ctags \
    --languages=python \
    -R \
    --python-kinds=-i \
    --exclude=*.pyc \
    -f tags \
    $PWD \
    $CONDA_PREFIX/lib/python*/*
