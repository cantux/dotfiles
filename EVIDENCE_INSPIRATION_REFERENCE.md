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

## 2026-10-08 — helm, kind, kubectl provenance

### Primary sources (checked on this box)

- `dnf history info 17`: begin 2026-04-27 17:44:02, command line
  `-y install --disableexcludes=kubernetes kubelet-1.31.0 kubeadm-1.31.0
  kubectl-1.31.0`, packages from `@kubernetes`; transaction 20 (2026-04-28)
  upgraded them to 1.31.14.
- `/etc/yum.repos.d/kubernetes.repo`:
  `baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/`.
- `rpm -qf /usr/bin/kubectl` → `kubectl-1.31.14-150500.1.1`;
  `rpm -qf /usr/local/bin/helm` → not owned by any package.
- `~/Projects/TokenBase/infra/scripts/10-os/laptop-prep.sh` lines 47-75:
  repository file generation, the dnf line, the helm tarball step and its
  comment on sudo `secure_path`.
- `stat` mtimes of `~/bin/*` and `/usr/local/bin/helm`; `helm version
  --short`, `kubectl version --client`, `kind version` on each copy.
- `dnf --showduplicates list --available helm` and `dnf repoquery --qf
  '%{buildtime}' helm`: `helm-4.1.1-1.el10_2`, EPEL, built 2026-02-11.
- `dnf provides '*/bin/kind'`: no match. `snap find kind`: no kind package.
- `grep -rn` over `~/Projects` for `~/bin`, `$HOME/bin`, `/home/ctuk/bin`,
  `kind.sigs.k8s.io/dl`, `dl.k8s.io`, `get.helm.sh`: only this worklog and
  the TokenBase and prep helm-installer lines.

### External sources

- Helm project, "Helm 4 Released" (helm.sh/blog/helm-4-released,
  2025-11-17): v4.0.0 released 2025-11-12; Helm 3 bug fixes until
  2026-07-08, security fixes until 2026-11-11.
- Helm v4.0.0 release notes (github.com/helm/helm/releases/tag/v4.0.0):
  "a major version with backward incompatible changes including to the flags
  and output of the Helm CLI"; chart apiVersion v2 "will continue to be
  supported"; "the majority of workflows remain compatible between Helm v3
  and v4"; kstatus-based waiting, WebAssembly plugin system, post-renderers
  as plugins, server-side apply.
- kind documentation, "Quick Start", Installation: release binaries from
  `kind.sigs.k8s.io/dl/<version>/kind-linux-amd64`, `go install
  sigs.k8s.io/kind@<version>`; community packages for Homebrew, MacPorts,
  Chocolatey, Scoop, Winget and Arch pacman; no RPM source.
- Kubernetes documentation, "Install and Set Up kubectl on Linux": the
  `dl.k8s.io/release/stable.txt` download path yields the newest release
  (1.36.0 on 2026-04-27); kubectl is supported within one minor version of
  the API server.
- GNU tar manual, "Attributes": extraction restores the archived
  modification time.

### Method

- Timeline reconstruction from independent records: file mtimes, the dnf
  history database, and the script whose lines generated the recorded dnf
  command line.
- Package-first check order: `rpm -qf` (owned?), `dnf provides`
  (available?), `snap find` (fallback?), then download.

### Verification sources, same day

- `journalctl -u kubelet --since -30min`: CrashLoopBackOff lines for
  `container=etcd` (151) and `container=kube-apiserver` (137);
  `systemctl show kubelet -p ActiveEnterTimestamp` → 2026-10-02 11:00:16.
- `ip -4 -br addr` (192.168.1.155/24), `ip route get 192.168.1.130`
  (on-link via wlp0s20f3), `ip neigh show 192.168.1.130` (INCOMPLETE),
  `ss -ltn` (no 6443 listener), `pgrep -a -f kube-` (controller-manager and
  scheduler only).
- `~/.kube/config` `server:` line; `/etc/hosts` line 8;
  `ls -la /etc/kubernetes /etc/kubernetes/manifests` (dated 2026-04-27 21:43).
- `TokenBase/infra/scripts/20-k8s/control-plane-up.sh` lines 11-24, 42, 52;
  `TokenBase/infra/scripts/lib/common.sh` lines 86-90 (`require_cmd`);
  `TokenBase/infra/scripts/10-os/verify-hosts.sh` line 16.
- `grep -rhoE -- '--kube-context ...'` over `prep/dist` (56 lima-spark,
  4 lima-dev); `command -v` for each companion tool; `bash -n` over every
  script that invokes kubectl or helm.
- kubeadm documentation, "Creating a cluster with kubeadm" and
  "Considerations about apiserver-advertise-address and
  ControlPlaneEndpoint": both values are fixed at init time and written into
  certificates, kubeconfigs and static pod manifests; a stable endpoint is
  the recommended guard against address change.
- kubeadm documentation, "Implementation details": the generated `etcd.yaml`
  lists the advertise address in `--listen-client-urls` and
  `--listen-peer-urls`. etcd documentation, "Configuration flags": listen
  URLs must name addresses the host holds. The observed etcd crash loop is
  consistent with the address 192.168.1.130 no longer being assigned.
