# Evidence, inspirations, references

Sources behind the changes recorded in `WORKLOG.md`.

## 2026-09-18 — large-file guards in `.vimrc`

### Primary sources (checked in the installed copies, not from memory)

- `:help profile` — Vim's built-in vimscript profiler. Produced the per-function
  table that named `<SNR>159_PrintTag()` as the cost.
  Vim 9.1, `runtime/doc/repeat.txt`.
- `~/.vim/plugged/tagbar/doc/tagbar.txt`, `*g:tagbar_file_size_limit*` (line
  1134) — documents the byte-count threshold and the `:TagbarForceUpdate`
  override.
- `~/.vim/plugged/ale/plugin/ale.vim:89` — `g:ale_lint_on_enter` defaults to
  `v:true`; `autoload/ale/events.vim:186` registers the `BufWinEnter` autocmd
  that re-lints on buffer entry.
- `~/.vim/plugged/ale/autoload/ale.vim`, `ale#Var()` — resolves `b:ale_*` before
  `g:ale_*`, which is what makes the buffer-local guard work.
- `/usr/share/vim/vim91/autoload/dist/ft.vim:182`, `FTheader()` — `*.h` becomes
  `cpp` unless `g:c_syntax_for_h` is set. This is why a C header was handed to
  C++ linters.
- `~/.vim/plugged/YouCompleteMe/plugin/youcompleteme.vim:192` —
  `g:ycm_disable_for_files_larger_than_kb`, default 1000.

### Prior art the fix is modelled on

- **LargeFile.vim**, Charles E. Campbell (vim.org script #1506). The canonical
  Vim pattern: a `BufReadPre` autocmd that tests `getfsize(expand('<afile>'))`
  against a threshold and disables expensive per-buffer features. The ALE guard
  here is that pattern, narrowed to one plugin instead of globally turning off
  syntax, undo and swap.
- **YouCompleteMe's own `g:ycm_disable_for_files_larger_than_kb`**. The nearest
  prior art inside this same config: a plugin that already refuses to work on
  files past a byte threshold rather than trying and stalling. Tagbar and ALE
  were the two that lacked an equivalent default, so they got one.

### Method

- Brendan Gregg, *Systems Performance* (2nd ed., 2020), ch. 6 — sampling profile
  of an on-CPU process, and the rule of measuring before attributing. `perf
  record -F 199 -g -p <pid>` gave the first signal (deep `call_user_func`
  recursion, `utfc_ptr2len` hot), which pointed at interpreted vimscript rather
  than file I/O and justified switching to Vim's own profiler for symbol names.
- Differential/ablation measurement: four vimrc variants differing by one plugin
  each, same input file, same harness. This is what separated Tagbar (all of the
  blocking cost) from ALE (background CPU burn, re-armed per buffer switch).

### Parallels in other domains

The Tagbar behaviour — cache the expensive *extraction* but redo the expensive
*render* on every view change — is the classic missing-memoization bug in UI
frameworks: React re-rendering a 100k-row list because the parent's state
changed, fixed by virtualizing so only visible rows are built. Tagbar caches
`s:known_files` by mtime but has no equivalent guard on `RenderContent()`.

### Test input

`bpftool btf dump file /sys/kernel/btf/vmlinux format c` — the BPF CO-RE
workflow described in Andrii Nakryiko, "BPF Portability and CO-RE"
(nakryiko.com, 2020) and in `libbpf`'s documentation. The generated
`vmlinux.h` is the realistic large single-header case being optimised for.

## 2026-10-04 — `~/Applications` for hand-installed programs

### Primary sources (checked on this box)

- Config template embedded in
  `/opt/appimagelauncher.AppDir/usr/bin/{AppImageLauncher,AppImageLauncherSettings,appimagelauncherd}`
  (`strings <bin> | grep -A12 '^\[AppImageLauncher\]'`): `# destination =
  ~/Applications`, `# additional_directories_to_watch = ...`,
  `# ask_to_move = true`, `# enable_daemon = true`. Same keys as the upstream
  wiki: https://github.com/TheAssassin/AppImageLauncher/wiki (Configuration).
- `~/.local/share/applications/appimagekit_*.desktop`: `Exec=` and `TryExec=`
  under `~/Applications`, `X-AppImageLauncher-Version=3.0.0-beta-2`.
- `/proc/<pid>/fdinfo/*` of `appimagelauncherd`: one `inotify wd` line,
  `ino:111` (hex) = 273 = `stat -c %i ~/Applications`.
- `/proc/sys/fs/binfmt_misc/appimage-type2` and
  `/opt/appimagelauncher.AppDir/usr/lib/binfmt.d/appimagelauncher.conf`:
  interpreter path under `/opt`, flag `F`.
- `/usr/bin/appimagelauncherd`: shell wrapper ending in
  `exec /opt/appimagelauncher.AppDir/usr/bin/appimagelauncherd`.
- `rpm -qi appimagelauncher`: Vendor TheAssassin, repo `@commandline`,
  installed 2026-08-13.
- `~/.bash_profile` and `~/.profile`: "# Added by Antigravity CLI installer"
  above the `~/.local/bin` PATH export.

### Prior art the convention follows

- XDG Base Directory Specification 0.8 (2021), "Basics": `$HOME/.local/bin`
  is the user-specific executables directory and should be on PATH. Also
  systemd `file-hierarchy(7)`, "Home Directory".
- macOS per-user `~/Applications` (Apple, *File System Programming Guide*,
  "macOS Standard Directories"). AppImageLauncher borrowed the name; this
  convention extends it to non-AppImage programs.
- Homebrew `Cellar` + `brew link`, and GNU Stow: install each program into
  its own directory, then expose it through a symlink farm in one `bin`. Here
  the farm is `~/.local/bin` and the cellar is `~/Applications`.
- FHS 3.0, `/opt`: the system-level analogue for self-contained add-on
  packages, which is where the AppImageLauncher RPM itself lands.

### Method

- Ground truth from the running process (`/proc/<pid>/fdinfo` inotify inode)
  rather than from documentation of what the daemon should watch.
- A reversible probe (copy a non-AppImage ELF into the watched directory,
  wait, inspect, remove) to confirm the daemon ignores plain binaries.

### Added the same day

- calibre installer: https://calibre-ebook.com/download_linux documents
  `install_dir`, `isolated`, `version`;
  https://raw.githubusercontent.com/kovidgoyal/calibre/master/setup/linux-installer.py
  (`main()`) also takes `bin_dir`, `share_dir`, `ignore_umask`, caches the
  tarball in `tempfile.gettempdir()/calibre-installer-cache`, installs into
  `<install_dir>/calibre`, and skips `calibre_postinstall` under `isolated=y`.
- Python `tempfile.gettempdir()` honours `TMPDIR` (Python Library Reference,
  `tempfile`), which routes the installer's download cache into `~/Downloads`.
- GitHub REST API `GET /repos/cantux/dotfiles` returned 200 without
  authentication: the repository is public.
