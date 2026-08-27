# dotfiles (CentOS Stream 10)

My CentOS setup: shell, tmux, git, and a vim IDE (YCM + clangd, formatters,
linters, sanitizers). Branch `centos` is the CentOS port of the `mac` branch.
Tracked files are **copied** into `$HOME` by `sync.sh` — not symlinked.

## Quick start

Fresh machine — install everything and lay down the config (needs `sudo`):

```
./init.sh        # dnf packages (EPEL + CRB) + rustup + pipx tools, then sync.sh + vim plugins
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

### Ctrl+Enter to submit (terminal + tmux)

Keybindings are `enter`→newline, `ctrl+enter`→submit (`.claude/keybindings.json`,
identical to mac). For Ctrl+Enter to reach Claude as a *distinct* key, two pieces
are needed:

1. **A terminal that emits a distinct Ctrl+Enter — use `kitty`.** gnome-terminal
   can't (it sends Ctrl+Enter as plain Enter). `.config/kitty/kitty.conf` maps
   Ctrl+Enter to the CSI-u sequence `ESC[13;5u` — the same bytes iTerm2 sent on the
   mac branch — so it's deterministic, not reliant on flaky protocol negotiation.
2. **tmux ≥ 3.4 to relay it.** CentOS Stream 10 only packages tmux 3.3a, so build a
   newer one:
   ```
   ./install_tmux.sh        # builds tmux >= 3.4 into /usr/local (needs sudo)
   tmux kill-server         # then start a fresh tmux
   ```
   `.tmux.conf` carries `extended-keys-format csi-u` (guarded — a no-op on 3.3a).

> Prefer **Ctrl+J**? It's a single byte (LF) that submits reliably in *any* terminal
> with no setup. Bind `ctrl+j`→`chat:submit` and you need neither kitty nor the
> newer tmux for submitting. Ctrl+Enter (via kitty) is purely to match mac muscle memory.

### Session persistence (tmux-resurrect)

Sessions, window splits, working directories, and pane history can be persisted across machine reboots via `tmux-resurrect`:
- **Save session**: `Ctrl+b` + `Ctrl+s` (saves to `~/.local/share/tmux/resurrect/`)
- **Restore session**: `Ctrl+b` + `Ctrl+r`

## What's tracked

`sync.sh` copies: `.bashrc`, `.bash_aliases`, `.tmux.conf`, `.gitconfig`,
`.vimrc`, `.vim/`, `.claude/keybindings.json`, `.claude/settings.json`,
`.config/yapf/style`, `.config/clangd/config.yaml`, `.config/kitty/kitty.conf`.

It **excludes** `.vim/plugged`, `undodir`, `vimundo`, `.netrwhist` so a sync
never wipes installed plugins or undo history.

## Packages

`init.sh` enables **EPEL + CRB**, installs the `"Development Tools"` group
(gcc/g++/make/autoconf/git), then a single `dnf install` of the package set
below, plus the pipx CLI tools. rust-analyzer isn't packaged, so it's installed
via **rustup**.

| tool | dnf package | repo |
|---|---|---|
| bash-completion | `bash-completion` | baseos |
| borgbackup | `borgbackup` | EPEL |
| clang / clang-format / clang-tidy / clangd | `clang clang-tools-extra` | appstream |
| scan-build | `clang-analyzer` | appstream |
| cmake | `cmake` | appstream |
| cppcheck | `cppcheck` | EPEL |
| cscope | `cscope` | appstream |
| ctags (Universal Ctags 6.x) | `ctags` | EPEL |
| googletest | `gtest-devel` | EPEL |
| kitty (terminal — distinct Ctrl+Enter) | `kitty` | EPEL |
| llvm | `llvm` | appstream |
| node + npm | `nodejs nodejs-npm` | appstream |
| poppler | `poppler-utils` | appstream |
| python 3.12 | `python3 python3-devel python3-pip` | baseos/appstream |
| pipx | `pipx` | EPEL |
| qemu | `qemu-kvm qemu-img` | appstream |
| rclone | `rclone` | EPEL |
| tmux | `tmux` | baseos |
| valgrind | `valgrind` | appstream |
| vim (`+python3`) | `vim-enhanced` | appstream |
| rust-analyzer | via `rustup component add rust-analyzer` | rustup |

`init.sh` also installs `curl` and `rsync` (baseos, usually already present):
`curl` bootstraps rustup, `rsync` powers `sync.sh`.

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

ASan/UBSan/TSan work out of the box.

- `asan foo.cpp` / `tsan foo.cpp` — build with the sanitizer and run `./a.out`.
- `memcheck ./a.out` — leak/error check via **valgrind**. (Use this for
  uninitialized-read bugs: MSan is omitted because el10 ships no instrumented
  libc++, so it false-positives in the standard library.)
- `clang-tidy` / `scan-build` — from dnf `clang-tools-extra` / `clang-analyzer` (on PATH).

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

## Appendix: vim / YCM build on a fresh CentOS box

`dnf install vim-enhanced` gives a `+python3` build, so YCM can load. Check with
`vim --version | grep python3`.

vim-plug clones plugins but does **not** fetch YCM's submodules or compile
`ycm_core`. The `.vimrc` YCM line carries a build hook so `:PlugInstall` /
`:PlugUpdate` compiles it (needs `cmake`, `clang`, `python3-devel`):

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

EPEL's `ctags` (`/usr/bin/ctags`) is Universal Ctags 6.x — the real one Tagbar
and easytags expect (`.vimrc` points both at `/usr/bin/ctags`).
