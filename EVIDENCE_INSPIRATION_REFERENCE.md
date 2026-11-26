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

## 2026-10-22 — Claude Code effort: `max` is reachable only through the environment

### Primary sources (checked on this box)

- `~/.local/share/claude/versions/2.1.309` (293 MB), byte offsets found with
  `grep -a -b -o`, context read with `tail -c +N | head -c M`:
  - 240534458: `effortLevel:()=>B(["low","medium","high","xhigh"]).optional().catch(void 0).describe("Persisted effort level for supported models.")`;
  - 240535261: `modelSettings` with the same enumeration for
    `effortLevel`, and `maxEffortLevel`;
  - 129488860: description of `maxEffortLevel`, a cap that clamps `/effort`,
    `--effort` and `CLAUDE_CODE_EFFORT_LEVEL`;
  - 244168936: a sanitizer that persists only `low`, `medium`, `high` and
    `xhigh`, and `UA()`, which reads `CLAUDE_CODE_EFFORT_LEVEL` (`auto` and
    `unset` mean no override);
  - 263160125: the `/effort` messages when the variable overrides the request,
    and the suffixes "(saved as your default for new sessions)" and
    "(this session only)".
- `agy --help`: "--effort  Reasoning effort for the current CLI session
  (low|medium|high|xhigh|max)".
- `.codex/config.toml` line 2: `model_reasoning_effort = "max"`.
- The output of `/effort max` in the session of this entry: "Set effort level
  to max (this session only)".

### Method

- The enumeration of the persisted key excludes `max`, and `.catch(void 0)`
  turns an excluded value into "unset"; the environment variable therefore is
  the only persistent route to `max`. The effect on a new session is read from
  the code and not yet observed.

## 2026-11-06 — OpenClaw role files under dotfiles

### Primary sources (checked on this box)

- `~/.npm-global/lib/node_modules/openclaw/docs/concepts/agent-workspace.md`
  (OpenClaw 2026.10.4): lines 70–83 list the standard workspace files; line 77,
  `SOUL.md` is loaded every session; line 83, `IDENTITY.md` is created or
  updated during the bootstrap ritual; line 46, `openclaw onboard`,
  `configure` and `setup` create the workspace and seed the bootstrap files
  when missing; lines 52–55, `agents.defaults.skipBootstrap: true` is the
  setting for workspace files managed elsewhere; line 68, the Control UI edits
  these files in place.
- `.../docs/concepts/soul.md`, lines 38–41: the documented workflow lets the
  agent rewrite its own `SOUL.md`. A live edit can therefore precede a sync;
  the `import` and `diff` modes exist for that case.
- `.../docs/cli/agents.md`, lines 58–62: `openclaw agents add` creates the
  workspace; hence `import` once after an agent is created.
- `~/.openclaw/openclaw.json`, `agents.entries.*.workspace`: 35 entries under
  `~/.openclaw/workspaces/<id>`; `main` alone uses `~/.openclaw/workspace`, a
  git repository of its own, left untracked.
- `sync.sh`, the `items` loop: `cp` for files, `rsync -a --delete` for
  directories, always to the same relative path under `$HOME`. The repository
  path `openclaw/workspaces` is not the live path, so the role files need their
  own script, as `bin/sync-openclaw-baseline` already does for `AGENTS.md`.

### Prior art the mechanism follows

- The repository's own rule (`README.md`, "Quick start"): the repository copy
  is the source and `sync.sh` overwrites `$HOME`. The role files follow it;
  `openclaw.json` stays the documented exception (`openclaw/NOTES.md`, "Sync
  direction").
- Terraform's `import`: a resource that exists outside the source of truth is
  brought under management by copying its state in once, after which the
  source governs (HashiCorp, "Import existing resources",
  developer.hashicorp.com/terraform/cli/import; not retrieved in this
  session). The `import` mode is the same step for a workspace the CLI created.
- Showing the change before applying it: `rsync --dry-run` and `git diff`
  before `git checkout`. The `diff` mode shows what `apply` would overwrite.

### Method

1. Inventory with `find` over `~/.openclaw/workspaces`: 35 directories; 35
   each of `AGENTS.md`, `IDENTITY.md`, `SOUL.md`, `USER.md`; 10 `DREAMS.md`;
   22 `memory/`; four run artifacts of 2026-10-16 and 17.
2. The secret regex of `bin/snapshot-openclaw` over every `SOUL.md` and
   `IDENTITY.md`: no match.
3. `bin/sync-openclaw-workspaces import`, then `diff` (identical), then
   `apply` (0 of 70 written), then `cmp` per file.

## 2026-11-06 — OpenClaw second pipeline

### Primary sources (checked on this box)

- `~/.npm-global/lib/node_modules/openclaw/docs/cli/agent.md` (OpenClaw 2026.10.4):
  "Other agent entry points keep their existing rule that a user-selected
  model disables configured fallbacks"; the basis of the manager rule to spawn
  without a model parameter (ISSUES.md, fix 4). The same page gives
  `--session-key agent:<id>:<key>` and `--timeout`, used by the driver script
  and the smoke test.
- `~/.openclaw/openclaw.json`, `agents.entries.pipeline_manager`: the
  `subagents.allowAgents` list, `requireAgentId` and `delegationMode: prefer`,
  copied into the second manager's entry with the `_v2` identifiers.
- The configuration write log of this session: write times 41, 55, 97, 128
  and 161 s for the five accepted entries, eleven refusals naming only
  `antigravity/` references, `openclaw models list` timing out, and the same
  eleven entries accepted in 194 s after `openclaw gateway restart`. The
  refusal came from the gateway's state, not from the entries.
- `~/.openclaw/workspaces/pipeline_manager_v2/` after the smoke test: a
  `USER.md` appeared that the sync did not write, so OpenClaw seeds missing
  bootstrap files at a session's start (`docs/concepts/agent-workspace.md`,
  lines 46 and 52–55, describe the seeding and `skipBootstrap`).

### Prior art the mechanism follows

- Running the new version beside the old under new identifiers, with the old
  untouched until the new one is trusted: blue-green deployment (Martin
  Fowler, "BlueGreenDeployment", martinfowler.com/bliki; not retrieved in this
  session).
- One table and templates generating every role file and configuration entry:
  the deleted `regen_souls.py` and `setup_agents.py` of the first pipeline
  (`openclaw/NOTES.md` of 2026-10-18 named them); the generator now lives with
  the files it produces.

### Method

1. `diff` of each role's family variants after normalising the family name:
   identical, so one template per role suffices.
2. The generator was run, its output checked for leftover placeholders, and
   the configuration entries compared field by field with the live file after
   the writes (16 of 16 equal).
3. One identity probe through `openclaw agent` as the smoke test; no pipeline
   phase was run.

## 2026-11-10 — OpenClaw gateway on demand

### Sources

- Measurement: PSS from `/proc/<pid>/smaps_rollup` (Linux kernel
  documentation, "The /proc Filesystem", docs.kernel.org/filesystems/proc.html);
  peak from the cgroup file `memory.peak` ("Control Group v2",
  docs.kernel.org/admin-guide/cgroup-v2.html).
- OpenClaw 2026.10.4, under `~/.npm-global/lib/node_modules/openclaw/`:
  - `dist/service-C5e3lih7.mjs:479`: the Linux adapter sets
    `isLoaded: isSystemdServiceEnabled`.
  - `dist/lifecycle-core-DKTT_dMI.mjs:400` (`runServiceStop`) and `:515`
    (`runServiceRestart`): the branches for a service that is not loaded;
    without a recovery handler, restart ends in `failServiceNotLoaded`.
  - `dist/systemd-Ch3siJBj.mjs:370-375`: install runs `daemon-reload`,
    `enable` and `restart`; only `preserveAutoStart` skips `enable`.
  - `docs/cli/gateway/service.md:206` and `:227`: `gateway stop --disable`
    acts on launchd only.
- systemd.service(5), `Restart=`: systemd does not restart a service that it
  stopped on request. systemctl(1): `disable --now`, `try-restart`.
  loginctl(1): `enable-linger`.

### Prior art

- A unit installed but not enabled, started by hand: the systemd split between
  `enable` (start at boot or login) and `start` (start now), systemctl(1).
- Start on the first connection, stop when idle: inetd, systemd socket
  activation, and `systemd-socket-proxyd --exit-idle-time=`
  (systemd-socket-proxyd(8)). Not adopted: it adds a proxy in front of the
  gateway port, while OpenClaw sessions already begin and end by decision.

### Method

1. Located the unit, its enablement link, linger, and every reference to the
   gateway in the dotfiles, the Claude configuration and the crontab: only the
   `default.target.wants` link started it.
2. Read OpenClaw's lifecycle code to learn how `gateway start|stop|restart|install`
   treat a disabled unit.
3. A guard checked for client connections and agent processes; then
   `systemctl --user disable --now`; then enablement, activity, port, reverse
   dependencies, processes and MemAvailable.

## 2026-11-10 — sync.sh enforces the gateway's autostart policy

### Sources

- systemctl(1), `disable`: removes the symlinks that `enable` created. Run 2
  of the test shows that a second call succeeds without a change.
- `bin/sync-openclaw-baseline`, lines 12-28: rewrites every workspace
  `AGENTS.md` unconditionally, so the dry run reproduces its output in a
  scratch file and compares instead of running it.

### Prior art

- Convergent configuration: each run asserts the desired state and changes
  only what deviates. Mark Burgess, "A Site Configuration Engine", Computing
  Systems 8(2), 1995 (CFEngine); Ansible's `ansible.builtin.systemd_service`
  module with `enabled: false` (docs.ansible.com). Not retrieved in this
  session.
- The dry run follows `rsync --dry-run --itemize-changes` (rsync(1)) and the
  `diff` mode of `bin/sync-openclaw-workspaces`.

### Method

1. Dry run: `cmp` for each file item and for the three prompt copies;
   `rsync -a --delete -n -i -c` with the excludes of `sync.sh` for each
   directory item; `bin/sync-openclaw-workspaces diff`; the baseline
   simulation with the repository's `.claude/CLAUDE.md` as source; a
   parsed-JSON comparison of the differing `settings.json`.
2. Test: `systemctl --user enable` (without `--now`), then the step cut from
   `sync.sh`, twice, under `set -euo pipefail`.

## 2026-11-11 — Claude Code effort: `--effort` as a default that `/effort` can change

### Primary sources (checked on this box)

- `~/.local/share/claude/versions/2.1.322` (341 914 128 bytes), byte offsets
  found with `grep -a -b -o`, context read with `tail -c +N | head -c M`:
  - 283980485: `effortLevel:()=>B(["low","medium","high","xhigh"]).optional().catch(void 0)`,
    unchanged since 2.1.309; `maxEffortLevel` is a cap, not a default.
  - 287946928: `LNe`, the levels that the settings can hold (`low`, `medium`,
    `high`, `xhigh`).
  - 287947159: `Hw()` reads `CLAUDE_CODE_EFFORT_LEVEL`; `unset` and `auto`
    yield `null`; the parser `W4` returns no value for the empty string.
  - 287951849: `ry()`, the resolution order
    `v=c??(c===null?m:void 0)??r??n??m` with `c` the variable, `r` the agent
    or turn effort, `n` the session level and `m` the model default; a hook
    value returns before this line.
  - 287953373: `kFt(e)` builds `{sessionEffort:Be(hEo(e)),settingsEffortTable:RZe()}`;
    304539662: the initial state takes `...kFt(r.effort)` from the
    command-line option.
  - 308268531: the `/effort` handler. When `Hw()` yields a level that differs
    from the request it answers "CLAUDE_CODE_EFFORT_LEVEL=… overrides this
    session — clear it and … takes over"; otherwise "Set effort level to …"
    with "(saved as your default for new sessions)" or "(this session only)".
  - 308277697: the non-interactive `/effort`: `current` and `status` report
    the level; the argument that permits saving is `!isNonInteractiveSession`.
  - 301957424: `subagentEffort:Jy(n,p,a.effort??…)`; 318551816: "omit to
    inherit the session effort".
  - 288477212: `applyConfigEnvironmentVariables` assigns the `env` map of each
    settings source to `process.env`; the observation of 2026-11-11 (a removed
    key stays, a changed value arrives within 3 s) agrees with it.
- `claude --help` (2.1.322): `--effort <level>  Effort level for the current
  session (low, medium, high, xhigh, max)`. An unknown value prints a warning
  and the session uses the default.
- bash(1) on this box, builtin `command`: "Run command with args suppressing
  the normal shell function lookup." Section ALIASES: "Aliases are expanded
  when a function definition is read, not when the function is executed,
  because a function definition is itself a command." A test confirms it: a
  function defined before an alias of the name it calls runs the later
  function of that name; a function defined after the alias runs the alias.

### Prior art

- `bin/gemini` in this repository appends `--effort max` when the caller
  passed none.
- `/etc/profile.d/colorls.sh`, line 53, on this box:
  `alias ls='ls --color=auto'`. The distribution supplies a default option
  through the shell, and an explicit option on the command line still wins.

### Method

1. Probes: `env -i HOME=… USER=… LOGNAME=… PATH=/usr/local/bin:/usr/bin:/bin
   TERM=… LANG=… XDG_RUNTIME_DIR=… timeout 150 bash -ic 'claude -p "/effort
   status"'`, and the same with `/effort xhigh`, `--effort low` and
   `command claude`. `md5sum ~/.claude/settings.json` before and after.
2. Running session: `env | grep CLAUDE_CODE_EFFORT_LEVEL` and
   `CLAUDE_EFFORT` in the session's tool shell after each sync;
   `/proc/<pid>/environ` for the start environment.

## 2026-11-11 — clangd: C files get `-std=gnu11`

### Sources

- clangd configuration reference, https://clangd.llvm.org/config (retrieved
  2026-11-11): "Each file can contain multiple fragments separated by ---
  lines"; "PathMatch: The file being processed must fully match a regular
  expression"; "PathExclude: The file being processed must not fully match a
  regular expression"; "Changes should take effect immediately as you
  continue to edit code."
- `clangd --check=<file>` (clangd 22.1.8) prints the compile command and the
  errors of one file under the user configuration; `XDG_CONFIG_HOME` selects
  the directory that holds `clangd/config.yaml`.

### Method

1. Candidate configuration under a scratch `XDG_CONFIG_HOME`; `clangd
   --check` on `linked_list.c`, `uniq_linked_list.cpp` and a header that
   includes `<span>`, under the live and the candidate configuration.
2. After `./sync.sh`: `clangd --check` on the six sources of
   `~/Projects/epi/cxx/linked_list/bootcamp`.

## 2026-11-25 — check targets in the C++ Makefile template

### Primary sources

- Clang, *AddressSanitizer*, "Usage": `-O1` for performance, `-fno-omit-frame-pointer` for stack traces. https://clang.llvm.org/docs/AddressSanitizer.html#usage
- Clang, *UndefinedBehaviorSanitizer*, "Usage": most checks recover by default; `-fno-sanitize-recover` exits the program at a report. https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html#usage
- Clang, *MemorySanitizer*, "Handling external code": every linked library needs instrumentation, so the template omits MSan. https://clang.llvm.org/docs/MemorySanitizer.html#handling-external-code
- GCC, *libstdc++ Manual*, "Macros", entry `_GLIBCXX_ASSERTIONS`. https://gcc.gnu.org/onlinedocs/libstdc++/manual/using_macros.html
- Clang, *User's Manual*, "Enabling All Diagnostics": Clang does not recommend `-Weverything` for general use. https://clang.llvm.org/docs/UsersManual.html#enabling-all-diagnostics
- LLVM, `clang/lib/StaticAnalyzer/Frontend/AnalysisConsumer.cpp`, function `shouldSkipFunction`: "if we visited the function before, do not reanalyze it". https://github.com/llvm/llvm-project/blob/main/clang/lib/StaticAnalyzer/Frontend/AnalysisConsumer.cpp
- clangd, *Configuration*, "ClangTidy": clangd merges `.clang-tidy` files with its own configuration. https://clangd.llvm.org/config#clangtidy
- GCC 14 manual (`man gcc`): the sub-options of `-fsanitize=undefined`; "The analyzer is only suitable for use on C code in this release."
- Valgrind manuals, installed under `/usr/share/doc/valgrind-docs/html/`: Memcheck section 4.2 (error categories); Helgrind's three error classes; DRD `--check-stack-var` with default `no`.
- `rpm --eval '%{optflags}'` on this machine: `-Wp,-D_GLIBCXX_ASSERTIONS`.

### Inspirations

- Linux kernel `make W=n` (help text in `~/src/linux/Makefile`): numbered warning levels, here `WARN_LEVEL`.
- J. Turner et al., *C++ Best Practices*, chapter 2, "Use the Tools Available": level 1 holds the flags it says to use, level 2 the portable flags it says to consider. https://github.com/cpp-best-practices/cppbestpractices/blob/master/02-Use_the_Tools_Available.md
- OpenSSF, *Compiler Options Hardening Guide for C and C++*: warning flags and `_GLIBCXX_ASSERTIONS`. https://best.openssf.org/Compiler-Hardening-Guides/Compiler-Options-Hardening-Guide-for-C-and-C++.html
- GNU Coding Standards, "Standard Targets for Users": `check` runs the self-tests. https://www.gnu.org/prep/standards/html_node/Standard-Targets.html

### Method

- One scratchpad directory per defect class, run through each target, with the exit status as the verdict.
- A minimal Language Server Protocol client sent `initialize` and `textDocument/didOpen` to clangd and printed the published diagnostics, because `clangd --check` prints no clang-tidy findings.

## 2026-11-25 — 2-space indentation in templates, generators and configuration

### Primary sources (checked in the installed copies)

- `man git-config`: "The syntax is fairly flexible and permissive. Whitespace characters, which in this context are the space character (SP) and the horizontal tabulation (HT), are mostly ignored."
- `python3 -m json.tool --help`: "--indent INDENT  separate items with newlines and use this number of spaces for indentation".
- `clang-format --style=Google --dump-config`: `IndentWidth: 2`; `AllowShortFunctionsOnASingleLine` with `Empty`, `Inline` and `Other` set to `true`.
- `.config/yapf/style`: `indent_width = 2`.

### Method

- Indent-width classification of every tracked file except Markdown, logs and evidence captures: a file counts as 4-space when it has lines at width 4 and none at a width of 2 modulo 4.
- Equivalence checks: `git config --file <file> --list` before and after the edit; the Containerfile with continuation lines joined and spaces squeezed, before and after the edit.

## 2026-11-26 — Consolidation of system drift and uncommitted work

### Method

- Drift: for each path of `sync.sh`, `cmp` (files) or `diff -rq` with the excludes of `sync.sh` (directories) between the repository and `$HOME`; `cmp` for `.codex/AGENTS.md`, `.gemini/config/rules/GEMINI.md` and `~/AGENTS.md` against their sources.
- Placement: `git diff --quiet centos centos_xps_9700 -- <file>` for each modified file; a parent directory present on `centos` for each new path.
- Credentials: a pattern scan for keys, tokens, secrets, passwords, bearer values, `sk-`, `ghp_`, `xox?-`, `AKIA` and private-key blocks over every committed file, and a walk of `openclaw/openclaw.json` for keys named like credentials.
