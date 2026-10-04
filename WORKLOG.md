# WORKLOG

Chronological record of changes to this repo, with the evidence behind them.

## 2026-09-18 — vim: 90+ s to open a large generated header

### Symptom

Opening `vmlinux.h` (bpftool-generated BTF header) took ~1 minute. Switching
away to another buffer and back cost the same again.

### Measurement setup

Test file generated on this box:

```
bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h   # 3.0 MB, 143355 lines
```

Method: run vim under `tmux new-session -d`, sample `utime+stime` from
`/proc/<pid>/stat` once per second, and count the interval where vim burns CPU.
External tools (`ctags`, `cpplint`) were replaced by logging shims to count
invocations. Variant vimrcs isolated one plugin at a time.

### Results

Reading the file is not the problem: `vim -u NONE` opens the 30 MB stress copy
in 0.11 s. `syntax on` adds nothing measurable; `undofile` adds 0.12 s.

| config (3 MB vmlinux.h)        | open   | switch back |
|--------------------------------|--------|-------------|
| full vimrc                     | 102 s  | 20 s        |
| Tagbar auto-open removed       | 0.26 s | 0 s         |
| ALE disabled, Tagbar kept      | 86 s   | —           |
| both removed                   | 0.23 s | 0 s         |

`:profile` over one buffer switch named the cost directly:

```
count     total (s)      self (s)  function
103431  26.885739025  20.844805500  <SNR>159_PrintTag()
    10  17.563466823   0.001159982  <SNR>159_AutoUpdate()
     2  17.514635736   0.085219126  <SNR>159_RenderContent()
     2  17.424942964   0.403639682  <SNR>159_PrintKinds()
```

`ctags` itself is cheap (0.39 s on 3 MB, 3.97 s on 30 MB) and ran exactly once.
The cost is Tagbar re-printing all 103431 tags into its sidebar — one vimscript
function call per tag — every time the current buffer changes.

Second, independent cost: vim maps `*.h` to filetype `cpp` (`dist#ft#FTheader`,
no `g:c_syntax_for_h` set), so ALE ran the C++ linters. On 3 MB, `cpplint`
takes 23.2 s and `cppcheck` had not finished at 900 s. `g:ale_lint_on_enter`
defaults to true and was never overridden, and ALE registers
`autocmd BufWinEnter * call ale#events#LintOnEnter()`, so both restart on every
buffer switch. Verified with a shim: 3 buffer switches produced 3 cpplint runs.

YCM was not a factor — `g:ycm_disable_for_files_larger_than_kb` defaults to
1000 KB, so it already skips these files.

### Change

`.vimrc`, two additions, both with documented escape hatches:

```vim
let g:tagbar_file_size_limit = 1024 * 1024      " :TagbarForceUpdate overrides

augroup ale_skip_huge_files
  autocmd!
  autocmd BufReadPre * if getfsize(expand('<afile>')) > 1024 * 1024
        \ | let b:ale_enabled = 0
        \ | endif
augroup END
```

`ale#Var()` reads `b:ale_enabled` before `g:ale_enabled`, so the buffer-local
flag is honoured; `:ALEToggleBuffer` re-enables linting for that buffer.

### After

| file                | open  | switch back | ctags | cpplint |
|---------------------|-------|-------------|-------|---------|
| vmlinux.h (3 MB)    | 1 s   | 0 s         | 0     | 0       |
| vmlinux30.h (30 MB) | 0 s   | 0 s         | 0     | 0       |

Regression check: a normal `.cpp` file still gets its Tagbar tree rendered and
still runs cpplint.

## 2026-10-04 — `~/Applications` as the home for hand-installed programs

### Question

Does keeping binaries and runnables in `~/Applications` interfere with
AppImageLauncher, and does the dotfiles baseline install anything that has to
move?

### Findings

AppImageLauncher 3.0.0-beta-2 (upstream release RPM, installed by hand on
2026-08-13; `init.sh` does not install it) already uses `~/Applications`:

- Default integration destination is `~/Applications`. No
  `~/.config/appimagelauncher.cfg` exists, and the config template embedded in
  all three binaries reads `# destination = ~/Applications`.
- Both integrated AppImages (GIMP 3.2.4, qBittorrent 5.2.3) live there; their
  `~/.local/share/applications/appimagekit_*.desktop` entries point `Exec=`
  at `~/Applications/...`.
- `appimagelauncherd` (user service) holds exactly one inotify watch, on inode
  273 = `~/Applications`. `~/Downloads` is not watched.
- Non-AppImage files are ignored: `antigravity/` has sat there since
  2026-08-16 with no entry, and a probe (`cp /usr/bin/true
  ~/Applications/ail-probe-true`, 4 s wait) produced no desktop entry. The
  probe was removed afterwards.
- Moving AppImageLauncher itself would break it: binfmt_misc registers
  `/opt/appimagelauncher.AppDir//usr/lib/x86_64-linux-gnu/appimagelauncher/binfmt-interpreter`
  (flag `F`), `/usr/bin/appimagelauncherd` is a wrapper that execs into
  `/opt/appimagelauncher.AppDir`, and the desktop entries' remove/update
  actions hardcode the same path.

Baseline (`init.sh`) installs nothing into `~/Applications` or `~/bin`: dnf
(`/usr`), rustup (`~/.cargo/bin`), pipx (`~/.local/bin`), vim-plug and TPM
(plugin dirs). PATH from `.bashrc`: `~/.local/bin`, `~/.npm-global/bin`,
`~/.cargo/bin`. `~/bin` is on no PATH (absent from `.bashrc`,
`.bash_profile`, `/etc/profile`), so `~/bin/{helm,kind,kubectl}` are
unreachable; `helm` and `kubectl` resolve to `/usr/local/bin` and `/usr/bin`.

Already following the convention: `~/Applications/antigravity/` exposed by
`~/.local/bin/antigravity -> ~/Applications/antigravity/antigravity`.

### Change

- `CLAUDE.md` (synced to `~/CLAUDE.md` and `~/AGENTS.md`): new section
  "Where programs live".
- `.bashrc`: the comment on the `~/.local/bin` PATH line states the convention.
- `init.sh`: `mkdir -p "$HOME/Applications"` before the dotfiles step.
- `README.md`: "Where programs live" section.
- `./sync.sh` applied.

Left alone: `~/bin/{helm,kind,kubectl}` (dead copies; delete or adopt by
hand), `~/.local/bin/agy` (placed by the Antigravity CLI installer, which also
wrote the PATH lines in `~/.bash_profile` and `~/.profile`).

### Follow-up, same day: refinement, consolidation, commits

- Refined the rule after review: `~/Downloads` keeps the download itself;
  `~/Applications` keeps what it unpacks or installs into. Self-installing
  tools may keep landing in `~/.local/bin`, which is on PATH via `.bashrc`
  (and again via the lines the Antigravity installer added to
  `~/.bash_profile` and `~/.profile`).
- Drift audit: every tracked item matched `$HOME` except
  `.claude/settings.json`, where the home copy carried `model` and an
  `autoMode` block written by Claude Code. Merged the home copy into the
  repo, then ran `./sync.sh`; the audit is clean.
- `cantux/dotfiles` is public (GitHub API answers 200 unauthenticated). The
  `autoMode` block names a private repo and its secret-file layout, so the
  merged `.claude/settings.json` stays uncommitted in the working tree for a
  human to review and commit.
- Commits split by topic: vim large-file guards (2026-09-18 work), one
  `.clang-format` source, clangd check removal, `lll` alias, effort-rule
  wording, `~/Applications` convention.
- calibre (next install): the upstream installer takes `install_dir`,
  `bin_dir`, `share_dir`, caches the tarball under
  `$TMPDIR/calibre-installer-cache`, and creates `<install_dir>/calibre`.
  Command recorded in README.
