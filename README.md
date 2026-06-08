# dotfiles (macOS / Apple Silicon)

My Mac setup: shell, tmux, git, and a vim IDE (YCM + clangd, formatters,
linters, sanitizers). Branch `mac` is the macOS port of the original Linux
dotfiles. Tracked files are **copied** into `$HOME` by `sync.sh` — not symlinked.

## Quick start

Fresh machine — install everything and lay down the config:

```
./init.sh        # Homebrew + formulae + pipx tools, then sync.sh + vim plugins
```

Already set up — after editing any file in this repo:

```
./sync.sh        # copy tracked files into $HOME
```

Reload without a new shell: `source ~/.bashrc` · `tmux source-file ~/.tmux.conf` ·
`:source $MYVIMRC` in vim.

> **Cardinal rule:** edit the copy in this repo, then `./sync.sh`. Never edit the
> `$HOME` copy directly — the next sync overwrites it. `sync.sh` does `cp`/`rsync`,
> not symlinks.

## What's tracked

`sync.sh` copies: `.bashrc`, `.bash_aliases`, `.tmux.conf`, `.gitconfig`,
`.vimrc`, `.vim/`, `.claude/keybindings.json`, `.claude/settings.json`,
`.config/yapf/style`, `.config/clangd/config.yaml`.

It **excludes** `.vim/plugged`, `undodir`, `vimundo`, `.netrwhist` so a sync
never wipes installed plugins or undo history.

## Packages

`init.sh` installs the Homebrew leaves (formulae installed on request, not
deps) plus the pipx CLI tools. Regenerate the formula list any time with:

```
brew leaves --installed-on-request
```

pipx tools: `yapf` (Python formatter), `cpplint` (Google C++ linter).

## vim

A single IDE around YCM. YCM **is** the LSP client — don't add a second one
(coc/vim-lsp); feed servers into YCM instead.

### Format — `,F`

vim-codefmt (Google maktaba/codefmt/glaive). `,F` = `:FormatCode` (whole file),
visual `,F` = `:FormatLines`.

- **C/C++** → clang-format, Google style (2-space), set in `.vimrc`.
- **Python** → yapf, 2-space to match (config: `~/.config/yapf/style`).

### Lint / static analysis

- **clang-tidy** runs inside **clangd** (`g:ycm_clangd_args = ['--clang-tidy']`);
  checks + `-std=c++20` live in `~/.config/clangd/config.yaml`. Shows inline.
- **ALE** adds what clangd doesn't: **cpplint** + **cppcheck** (signs only; it
  leaves the location list to YCM). Jump ALE results with `]a` / `[a`.

### Sanitizers / leaks (shell helpers in `.bash_aliases`)

macOS supports ASan/UBSan/TSan; **MSan is not available** on macOS.

- `asan foo.cpp` / `tsan foo.cpp` — build with the sanitizer and run `./a.out`.
- `memcheck ./a.out` — leak check via Apple's `leaks` (no LeakSanitizer on mac).
- `clang-tidy` / `scan-build` — aliases to keg-only Homebrew llvm.

### Navigation

- **YCM** (semantic): `,g` GoTo · `,r` references · `,def` / `,dec` def/decl ·
  `,i` impl · `,t` type · `,o` outline · `,D` doc · `,h` hover · `,R` rename ·
  `,fx` fixit · `,ca` / `,ce` callers/callees. Diagnostics: `,dd`, jump `]d`/`[d`.
- **cscope + ctags** (for external trees like glibc/kernel): `,fg` global def ·
  `,fs` symbol · `,fc` callers · `,fd` callees. `<C-]>` jump, `<C-t>` back, `g]`
  list. Build an index from a project root: `ctags -R .` (writes `./tags`).
- `,mk` reads the C++ Makefile skeleton (`~/.vim/templates/Makefile`).
- F5 toggles the Tagbar outline.

### Editor tweaks

- Indent 2 spaces (`expandtab`, `tabstop`/`shiftwidth`/`softtabstop=2`).
- Tabs→spaces on save (`retab` on `BufWritePre`; skips `make`/`go`).
- SGR mouse on so the wheel scrolls inside tmux.

## Appendix: vim / YCM build on a fresh Mac

System vim (`/usr/bin/vim`) is built `-python3`, so YCM can't load there.
`brew install vim` gives a `+python3/dyn` build, and `/opt/homebrew/bin` is ahead
of `/usr/bin` on PATH, so it shadows the system vim. Check with
`vim --version | grep python3`.

vim-plug clones plugins but does **not** fetch YCM's submodules or compile
`ycm_core`. The `.vimrc` YCM line carries a build hook so `:PlugInstall` /
`:PlugUpdate` compiles it:

```vim
Plug 'ycm-core/YouCompleteMe', { 'do': './install.py --clangd-completer' }
```

One-time manual build (do it with no vim open on the YCM repo):

```
cd ~/.vim/plugged/YouCompleteMe
git submodule update --init --recursive
python3 install.py --clangd-completer      # clangd = C/C++, bundled jedi = Python
```

Extra language servers go **through** YCM via `g:ycm_language_server`
(e.g. `rust-analyzer`, `typescript-language-server`).

Apple's `/usr/bin/ctags` is a stub — `brew install universal-ctags` lands a real
one at `/opt/homebrew/bin/ctags` and shadows it.
