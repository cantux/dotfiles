# unix_env_setup

Make backups of the default dotfiles at your home then copy this directory entirely and restart terminal.
```
mkdir dotfile_bak
cp .* dotfile_bak/.
```

## Vim

### macOS (Apple Silicon) setup

The system vim (`/usr/bin/vim`) is built with `-python3` — no Python. YCM is a
Python plugin, so it can't load there. You'll see:

```
YouCompleteMe unavailable: requires Vim compiled with Python (3.12.0+) support.
```

Fix: install a vim with Python.

```
brew install vim                 # bottle is built +python3/dyn (loads brew python3 at runtime)
vim --version | grep python3     # expect +python3/dyn  (system vim shows -python3)
```

`/opt/homebrew/bin` is already ahead of `/usr/bin` on PATH, so the brew vim
shadows the system one. Just open a new shell.

#### Build YCM (one time)

vim-plug only clones plugins; it does NOT fetch YCM's git submodules or compile
`ycm_core`. The auto-installer in `.vimrc` only checks if the top-level plugin
dir exists, so it can't tell that YCM is unbuilt — that's why it looked like it
kept "reinstalling." Two fixes:

1. Build deps + servers:

```
brew install cmake node rust-analyzer universal-ctags
# cmake builds ycm_core; node runs the TS server; universal-ctags for tags/Tagbar
npm install -g typescript-language-server typescript
```

2. Fetch submodules + compile (do this with NO vim open on the YCM repo — a
   second git process corrupts it):

```
cd ~/.vim/plugged/YouCompleteMe
git submodule update --init --recursive      # big download (clang + jedi deps)
python3 install.py --clangd-completer        # builds ycm_core; clangd = C/C++, jedi (bundled) = Python
```

Make it self-healing: add a build hook to the YCM line in `.vimrc` so
`:PlugInstall`/`:PlugUpdate` compiles it automatically:

```vim
Plug 'ycm-core/YouCompleteMe', { 'do': './install.py --clangd-completer' }
```

#### LSP servers (through YCM, not beside it)

YCM **is** an LSP client. Don't run a second client (vim-lsp/coc) next to it —
that causes duplicate popups/diagnostics. Feed servers into YCM instead. clangd
(C/C++), jedi (Python), gopls (Go), Java are handled by YCM directly. Add the
rest in `.vimrc`:

```vim
let g:ycm_language_server = [
  \ { 'name': 'rust', 'cmdline': ['rust-analyzer'], 'filetypes': ['rust'] },
  \ { 'name': 'typescript', 'cmdline': ['typescript-language-server', '--stdio'],
  \   'filetypes': ['typescript','javascript'] },
  \ ]
```

Useful YCM maps already in `.vimrc`: `,g` GoTo, `,r` GoToReferences,
`,def` GoToDefinition, `,dec` GoToDeclaration. Completion: auto as-you-type,
`<C-Space>` to force it, `<C-n>`/`<C-p>` to pick, `<CR>` to accept.

#### ctags

Apple's `/usr/bin/ctags` is a useless stub. Install Universal Ctags and the
`.vimrc` points Tagbar/easytags at it:

```
brew install universal-ctags        # lands at /opt/homebrew/bin/ctags, shadows the stub
```

Build a project index from its root, then jump with tags:

```
ctags -R .          # writes ./tags  (.vimrc has: set tags=tags,./tags)
```

`<C-]>` jump to definition under cursor, `<C-t>` jump back, `g]` list matches.
For C/C++/Python prefer YCM's `,g` (semantic) — tags are the fallback and also
feed YCM's identifier completion. F5 toggles the Tagbar outline.

#### Editor tweaks in .vimrc

- **Indent**: 2 spaces (`tabstop`/`shiftwidth`/`softtabstop=2`, `expandtab`).
- **Tabs→spaces on save**: `BufWritePre` runs `retab` (skips `make`/`go` which
  need real tabs).
- **Insert-mode word edits**: Option+Backspace deletes the previous word
  (needs terminal "Option as Meta"); Ctrl+Left / Ctrl+Right skip a word.
- **Makefile skeleton**: `,mk` in normal mode reads `~/.vim/templates/Makefile`
  (a plain C++ all/clean Makefile). On-demand, like `<C-T>` for the Python
  template.

#### sync.sh note

`sync.sh` uses `rsync` and **excludes** `plugged/`, `undodir`, `vimundo`,
`.netrwhist` so syncing never wipes installed plugins or undo history. Run it
with the absolute path so it can't execute from the wrong dir:
`bash ~/Projects/dotfiles/sync.sh`.

### Linux / Debian
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


