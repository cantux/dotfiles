#!/bin/bash

echo "Building ctags under this directory: ${PWD}"
ctags \
    -R \
#     --python-kinds=-i \
    --exclude=*/build/* \
    --exclude=*/dist/* \
    --exclude=*.pyc \
    -o tags \
    $PWD
