

external_modules="$(echo $CONDA_PREFIX/lib/python*)"

echo "def Settings( **kwargs ):
  return {
    'sys_path': [
      '${external_modules}'
      ],
    'interpreter_path': '${CONDA_PYTHON_EXE}'
  }" \ 
      > .ycm_extra_conf.py

