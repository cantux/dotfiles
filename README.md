# unix_env_setup

Make backups of the default dotfiles at your home then copy this directory entirely and restart terminal.
```
mkdir dotfile_bak
cp .* dotfile_bak/.
```

## Vim
YouCompleteMe hard requires Vim 8.2+. 

First solution was to keep YCM version at a certain commit. I am keeping the line that does it.

Other solution is to update the vim version which debian don't have a decent backport yet.

```
# remove prev
sudo apt-get purge vim vim-common vim-gtk3

cd $vim_source
conda install gxx_linux-64              ## install latest gcc libs for python
./$dotfiles/build_vim_with_python.sh    ## configure vim with python3.8
```

### YCM tags creator
Creates tags with Conda env libraries included.

```
ycm_conf_from_conda_gen.sh
gen_conda_python_ctags.sh
```

## Ctags
### Install
Clone and install ctags if system don't have it.
```
~/.ctags/build_ctags_source.sh

```
### Setup
Run the following. It will install Plugged, then install all plugins

```
:PluggedInstall
```

Then in terminal run the following to copy colors and initialize YCM:

```
~/.vim/init.sh
```

## Aliases

### Copy Pasta to middleclick
Requires xclip:
```
cat anan | pbcopy
pbpaste | cat
```


