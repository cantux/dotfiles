#!/bin/bash

echo "Building django ctags under this directory: ${PWD}"
ctags -R --fields=+l --languages=python --python-kinds=-iv -f ./tags  \ 
    $(python -c "import os, sys; print(' '.join('{}'.format(d) for d in sys.path if os.path.isdir(d)))")

