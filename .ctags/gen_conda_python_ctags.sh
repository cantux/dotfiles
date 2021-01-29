#!/bin/bash

echo "Building ctags under this directory: ${PWD}"
ctags \
    --languages=python
    -R \
    --python-kinds=-i \
    --exclude=*.pyc \
    -o tags \
    $PWD \
    $CONDA_PREFIX/lib/python*/*
