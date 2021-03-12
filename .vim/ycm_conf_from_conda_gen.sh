#!/bin/bash

external_modules="$(echo $CONDA_PREFIX/lib/python*)"

cat > .ycm_extra_conf.py << EOL
def Settings( **kwargs ):
  return {
    'sys_path': [
      '${external_modules}'
      ],
    'interpreter_path': '${CONDA_PYTHON_EXE}'
  }
EOL

