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

## 2026-10-08 — helm, kind, kubectl: provenance and package audit

### Question

Why were `~/bin/{helm,kind,kubectl}` installed as loose binaries, do the
trials under `~/Projects/prep` reference them, and can a package manager
replace them?

### Findings

1. Provenance. `~/bin/kubectl` (v1.36.0) and `~/bin/kind` (v0.24.0) carry
   mtimes 2026-04-27 16:52:41 and 16:52:43: one manual download step. One
   hour later, dnf transaction 17 (begin 2026-04-27 17:44:02, command line
   `-y install --disableexcludes=kubernetes kubelet-1.31.0 kubeadm-1.31.0
   kubectl-1.31.0`) matches `TokenBase/infra/scripts/10-os/laptop-prep.sh`
   lines 56-60, and `/usr/local/bin/helm` (v3.20.2, mtime 17:44:12) matches
   its lines 67-75. `~/bin/helm` (v3.16.3) carries a 2024-11-13 mtime, which
   tar restores from the archive, so it is the archive's build time, not the
   installation time; v3.16.3 is the script's default `HELM_VERSION`. No
   PATH export on this host names `~/bin`, so the three copies never ran.
2. References. No file under `~/Projects` names `~/bin`, `$HOME/bin` or
   `/home/ctuk/bin`. The trials in `~/Projects/prep/dist/kubernetes` call
   `kubectl` and `helm` through PATH, mostly against Lima VMs
   (`--kube-context lima-spark`); none invokes `kind`, and neither does
   `~/Projects/TokenBase`.
3. Packages. kubectl: installed from the pkgs.k8s.io v1.31 repository
   (`kubectl-1.31.14-150500.1.1`), matching kubeadm/kubelet 1.31.14 on the
   laptop and the Pi workers' pinned `KUBERNETES_VERSION`. helm: EPEL 10
   ships `helm-4.1.1-1.el10_2` (built 2026-02-11); snap ships helm 4.3.0.
   The tarball step in `laptop-prep.sh` cites a sudo `secure_path` problem
   with the `get-helm-3` script, not package absence; its Helm 3 pin sits on
   a line whose bug-fix support ended 2026-07-08 and whose security support
   ends 2026-11-11. kind: no package in dnf (`dnf provides '*/bin/kind'`
   returns nothing), EPEL or snap; upstream lists pacman as the only Linux
   distribution package.

### Change

- Removed `~/bin/helm`, `~/bin/kind`, `~/bin/kubectl` and the empty `~/bin`.
  `helm` resolves to `/usr/local/bin/helm` (3.20.2), `kubectl` to
  `/usr/bin/kubectl` (1.31.14), `kind` to nothing.
- `CLAUDE.md` and `README.md`: "Where programs live" opens with the
  package-first rule and its two checks (`dnf provides`, `snap find`).

### Left for a decision

- Replace `/usr/local/bin/helm` with EPEL's Helm 4 (needs sudo; PATH puts
  `/usr/local/bin` before `/usr/bin`, so the tarball copy must go first) and
  switch `laptop-prep.sh` lines 64-75 to `dnf -y install helm`. Helm 4
  declares backward-incompatible CLI flags and output, kstatus-based
  waiting, a redesigned plugin system and post-renderers as plugins; the
  TokenBase helm scripts need one test run under it.

### Verification of the references, same day

1. Resolution. Every script under `~/Projects` reaches the tools through
   PATH: `helm` → `/usr/local/bin/helm` (3.20.2), `kubectl` →
   `/usr/bin/kubectl` (1.31.14), `kubeadm` 1.31.14. TokenBase's
   `require_cmd` (`lib/common.sh:86-90`) uses `command -v`, so its 23
   `require_cmd` lines are satisfied for helm, kubectl and kubeadm. `bash -n`
   passes on every script invoking kubectl or helm under TokenBase and
   prep/dist (0 failures). The two hard-coded paths, `laptop-prep.sh:67,75`
   and `verify-hosts.sh:16`, name `/usr/local/bin/helm`, which exists;
   `verify-hosts.sh` also falls back to `command -v`.
2. TokenBase target. `~/.kube/config` and the kubelet point at
   `https://192.168.1.130:6443`. The laptop now holds 192.168.1.155/24 on
   `wlp0s20f3`; `ip neigh` reports 192.168.1.130 INCOMPLETE, so no host
   answers for that address. `control-plane-up.sh` lines 11-24 derive the
   advertise address and `controlPlaneEndpoint` (lines 42, 52) from the
   laptop's primary IPv4 at init time; `/etc/kubernetes` (admin.conf,
   manifests, pki) is dated 2026-04-27 21:43. Since kubelet started on
   2026-10-02 11:00, `etcd` has failed 151 times and `kube-apiserver` 137
   times (CrashLoopBackOff, 5 m back-off); nothing listens on 6443;
   `kube-controller-manager` and `kube-scheduler` run but cannot connect.
   Every `kubectl` and `helm` call against the farm fails with "no route to
   host" until the laptop regains 192.168.1.130 (DHCP reservation on the
   192.168.1.0/24 router) or the control plane is re-initialised on a stable
   endpoint; `cp.farm` resolves to 127.0.0.1 only (`/etc/hosts:8`).
3. prep/dist targets. 56 references use `--kube-context lima-spark`, 4 use
   `lima-dev`, and `distsys_sims/_infra/lib.sh:3` hard-codes `kubectl
   --context lima-dev`; neither context exists in `~/.kube/config`, and
   `limactl` is absent (27 scripts need it). Also absent: `aws` and `eksctl`
   (3 scripts each), `cilium` (14), `docker` (10), `hubble` (6), `yq` (3),
   `tinkerbell` (4). `distsys_sims/HANDOFF.md` lists the Linux migration
   options (kind, k3s, kubeadm) and is the only mention of `kind` as a
   command.
4. Helm 4 impact on the references. `laptop-prep.sh:67` re-downloads the
   tarball whenever `/usr/local/bin/helm` is missing, so a dnf Helm must be
   accompanied by editing lines 64-75; otherwise the next run restores the
   shadowing copy. The scripts use `--wait --timeout` (three places) and
   `--wait=false` (teardown), no plugins and no post-renderers.

## 2026-10-17 — agy: directory-confined autonomous execution wrapper (agy-project)

### Need

Enable autonomous Antigravity CLI execution with `--dangerously-skip-permissions --mode accept-edits` for project repositories while isolating the filesystem blast radius strictly to the working directory.

### Implementation

1. Created `containers/Containerfile.agy-dev` based on Red Hat Universal Base Image 9, installing developer toolchains (`git`, `python3`, `python3-pip`, `gcc`, `gcc-c++`, `make`, `which`, `findutils`). Built and verified `localhost/agy-dev:latest` under rootless Podman.
2. Added `agy-project()` shell function to `.bash_aliases`:
   - Executes `localhost/agy-dev:latest` with `--userns=keep-id` and `--net=host`.
   - Mounts `$PWD` read-write (`-v "$PWD:$PWD:Z" -w "$PWD"`).
   - Mounts `~/.gemini` read-write (`-v "$HOME/.gemini:$HOME/.gemini:Z"`) to preserve session state and authentication.
   - Mounts `~/.gitconfig` and host `/home/ctuk/.local/bin/agy` read-only.
   - Invokes `agy --dangerously-skip-permissions --mode accept-edits "$@"`.
3. Executed `./sync.sh` to synchronize `.bash_aliases` to `$HOME/.bash_aliases`.

## 2026-10-18, OpenClaw awareness and security audit

1. Added `bin/sync-openclaw-baseline` and a `sync.sh` hook: embeds `.claude/CLAUDE.md` into every `~/.openclaw/workspaces/*/AGENTS.md` between `baseline:begin`/`baseline:end` markers, idempotently; executed against 35 workspaces.
2. Added `bin/snapshot-openclaw` and `openclaw/NOTES.md`: reverse-direction redacted snapshot of `~/.openclaw/openclaw.json` into `openclaw/openclaw.json` (gateway auth token and any credential-shaped value replaced by REDACTED; the script refuses to write if a secret pattern survives). Forward `sync.sh` deliberately never writes the live OpenClaw config. First snapshot taken: 36 agent entries, one redaction (`gateway.auth.token`).
3. Security audit of this repository: working tree and full git history scanned for credential patterns (AIza, sk-, ghp_, gho_, xox, private-key blocks) — zero hits in any ref; word-level matches resolve to vim plugin documentation and this worklog; `.claude/settings.json` contains security-posture descriptions, no values. The repository is public (`cantux/dotfiles`); recommendation recorded in the session log to make it private.

## 2026-10-22 — install_llm_cluster_host.sh (merged_llm_serving host)

### Need

`~/Projects/ai/merged_llm_serving` runs four KVM machines under libvirt `qemu:///system`, passes the RTX 2060 into one of them by VFIO, and is operated from this host with kubectl/cilium/hubble at the cluster's versions.

### Implementation

1. New `install_llm_cluster_host.sh` (run as the user; it calls sudo):
   - installs libvirt KVM daemons, `virt-install`, `policycoreutils-python-utils`; enables the modular sockets `virtqemud`, `virtnetworkd`, `virtstoraged`, `virtnodedevd`; adds the user to `libvirt`;
   - creates the storage pool directory `/home/mls-pool` with SELinux type `virt_image_t` (`/` has 30 GB free, `/home` 60 GB);
   - adds kernel arguments `intel_iommu=on iommu=pt` to every kernel with grubby (RHEL 10 GPU-assignment guide); no boot-time `vfio-pci ids=` binding, because libvirt managed hostdev detaches and reattaches the GPU around the machine's lifetime;
   - installs `nsight-systems-cli` from NVIDIA's rhel10 devtools repo, for `nsys stats` on reports pulled from the GPU machine;
   - resets the dead host kubeadm install (API server 192.168.1.130) and disables kubelet;
   - installs into `~/.local/bin`, each checked against its published sha256: kubectl v1.36.5 (the host's 1.31 is outside the skew of a 1.36 API server), cilium-cli v0.20.1, hubble v1.20.2.
2. `--undo` removes the kernel arguments, disables the libvirt sockets, drops the group membership and deletes the three binaries.
3. `shellcheck` clean. Not yet executed: it needs the user's sudo and a reboot afterwards.

## 2026-10-22 — Maximum reasoning effort as the default of every agent

### Need

The author wants every model to work at its maximum reasoning effort by default. The persisted Claude Code level was `xhigh`; `/effort max` sets `max` for the current session only.

### Evidence

1. `claude` 2.1.309 (`~/.local/share/claude/versions/2.1.309`): the settings schema declares `effortLevel` as the enumeration `["low","medium","high","xhigh"]` with `.catch(void 0)`, so a value `"max"` is discarded without an error; `modelSettings.<model>.effortLevel` uses the same enumeration.
2. The same binary reads `CLAUDE_CODE_EFFORT_LEVEL` through a parser that accepts `["low","medium","high","xhigh","max"]` (`auto` and `unset` mean no override), and `/effort` reports that the variable overrides the requested level.
3. `.codex/config.toml` already holds `model_reasoning_effort = "max"`. `agy --help` lists `--effort` with `low|medium|high|xhigh|max`; `bin/gemini` appended `--effort high` when the caller passed none.

### Implementation

1. `.claude/settings.json`: added `"env": {"CLAUDE_CODE_EFFORT_LEVEL": "max"}`; kept `"effortLevel": "xhigh"` as the highest persistable fallback. Carried over `"model": "sonnet"` and `modelSettings` from the deployed file, where `/model` had written them; a sync would otherwise have restored `"model": "fable"`.
2. `.claude/CLAUDE.md`: one line in the baseline register: every model, and every agent it delegates to, runs at its maximum reasoning effort. The `effort` parameter of the Agent tool is set only when an instruction such as `CLAUDE.md` asks for a specific level.
3. `bin/gemini`: the default `--effort high` became `--effort max`.
4. Executed `./sync.sh`.

### Consequences

1. `/effort` cannot lower the level of a Claude Code session while the variable is set. A session at another level starts with `CLAUDE_CODE_EFFORT_LEVEL=high claude`.
2. The binary treats claude-3-*, claude-opus-4-0, claude-opus-4-1, claude-sonnet-4-0, claude-sonnet-4-5 and claude-haiku-4-5 as models without an effort setting; they ignore the variable.
3. Every Claude Code session of this account, among them the persistent session of `claude-slack-cli`, now runs at `max`.
4. The effect on a new session is read from the code, not observed. `/effort status` in a new session shows it.

## 2026-11-25 — vim: check targets in the C++ Makefile template

### Need

The author wants the C++ Makefile template (`,mk`) to run AddressSanitizer, ThreadSanitizer, several warning levels and clang-tidy, plus the further checks that the installed toolchain supports.

### Evidence

A scratchpad test bed held one directory per defect class; GCC 14.4.1, Clang 23.1.3, cppcheck 2.18.2, Valgrind 3.28.0 and gtest 1.14 ran it.

1. Each defect class fails exactly the targets meant to detect it: a heap overflow fails `asan` and `valgrind`; a leak fails `asan` (LeakSanitizer) and `valgrind`; a signed overflow fails `asan` (UndefinedBehaviorSanitizer); `v[i]` with `size() <= i < capacity()` fails every build through `_GLIBCXX_ASSERTIONS`, while ASan alone stays silent; a data race fails `tsan` and `helgrind`; an uninitialized heap read fails only `valgrind`; a leak on a path that no test executes fails only `clang-tidy` (`clang-analyzer-cplusplus.NewDeleteLeaks`) and `cppcheck` (`memleak`). The formatted gtest skeleton and a `solution.h`/`solution.cpp`/`solution_test.cpp` layout pass `make check`.
2. GCC reports `-Wmaybe-uninitialized` for a loop-assigned variable only at `-O2`, not under `-fsyntax-only` or `-O0`; `warnings` therefore compiles at `-O2` and links to `/dev/null`.
3. Clang rejects `-Wduplicated-cond`, `-Wduplicated-branches`, `-Wlogical-op` and `-Wuseless-cast` under `-Werror`; the warning levels omit them, so `CXX=clang++` works at every level.
4. GCC 14 and Clang 23 both refuse `-fsanitize=address,thread`; the template builds `main.asan` and `main.tsan` as separate binaries.
5. GCC 14.4 leaves `_GLIBCXX_ASSERTIONS` undefined at `-O0`; `rpm --eval '%{optflags}'` shows that RHEL defines it for every package.
6. clang-tidy 23 without a `.clang-tidy` file enables only `clang-diagnostic-*`. `TIDY_CHECKS` carries the clangd set of `.config/clangd/config.yaml` plus `clang-analyzer-*` and `misc-include-cleaner`: 371 checks. A Language Server Protocol probe showed that clangd 23.1.3 publishes no `clang-analyzer-*` and no `misc-include-cleaner` finding, so the template target is the only place where those checks run.
7. The Clang Static Analyzer analyzes a function only inside the gtest `TEST` that inlines it: `-analyzer-display-progress` lists the test body as the only entry point. With the solution in its own translation unit, the analyzer reports the leak.
8. DRD skips stack variables by default (`--check-stack-var=no`) and missed the race on a stack counter; Helgrind reported it. The template carries Helgrind.

### Implementation

1. `.vim/templates/Makefile`: `CXXFLAGS` gains `-D_GLIBCXX_ASSERTIONS`; the binaries also depend on `$(HDRS)`; new variant binaries `main.asan` (ASan with UBSan and `-fno-sanitize-recover=all`) and `main.tsan`; new targets `asan`, `tsan`, `valgrind`, `helgrind`, `format-check`, `warnings` (`WARN_LEVEL` 1 to 3), `clang-tidy` (`TIDY_CHECKS`), `cppcheck`, `cpplint`, and `check`, which runs `format-check warnings clang-tidy cppcheck cpplint test asan tsan valgrind`.
2. Merged `centos` into `centos_xps_9700` (`15be722`) with `git merge-tree --write-tree` and `git commit-tree`, because a porcelain merge refuses to change `WORKLOG.md` and `EVIDENCE_INSPIRATION_REFERENCE.md` while they carry uncommitted edits. The script overwrote only files without local edits and appended the new text to the two edited files. Each edited file now equals its pre-merge working copy followed by the appended text, the remainder reproduces the pre-merge diff line for line, and `git status` is unchanged.
3. Deployed `.vim` with the `rsync` command and excludes that `sync.sh` uses for that item; the dry run listed only `templates/Makefile`. Skipped the full `sync.sh`, because the deployed `~/.claude/settings.json` (`model`, `modelSettings.claude-opus-5-5.effortLevel`) and `~/.codex/config.toml` (`model`, trusted projects) hold runtime edits newer than the repo copies. `~/.vim/templates/Makefile` equals the repo template, and the deployed template passes `test`, `asan` and `clang-tidy` in a fresh directory.

### Consequences

1. `make check` runs `format-check`, `warnings` (level 1), `clang-tidy`, `cppcheck`, `cpplint`, `test`, `asan`, `tsan` and `valgrind`, and stops at the first failure; `make -k check` reports every failure.
2. The clang-tidy check list exists in three copies: `.config/clangd/config.yaml`, the tidy command in `.claude/CLAUDE.md`, and `TIDY_CHECKS` in the template, which adds `clang-analyzer-*` and `misc-include-cleaner`.
3. `format-check` fails on the gtest skeleton `.vim/templates/gtest.cpp`, which uses 4-space indentation, until vim formats the buffer on save.
4. cpplint requires header guards derived from the path relative to the repository root.
5. The runtime edits in `~/.claude/settings.json` and `~/.codex/config.toml` remain outside the repo; the next full `sync.sh` reverts them unless the repo copies take them over first.

## 2026-11-25 — 2-space indentation in templates, generators and configuration

### Need

The author wants every indentation to use 2 spaces; the gtest skeleton failed `make format-check` because of its 4-space indentation.

### Evidence

1. A scan classified every tracked file by its indent widths: a width of 2 modulo 4 marks 2-space indentation, while nested 2-space code also reaches width 4. Five files used 4-space indentation only: `.vim/templates/gtest.cpp`, `.gitconfig`, `containers/Containerfile.agy-dev`, and two EasyEffects presets under `.var/app/com.github.wwmm.easyeffects/`.
2. Two generators in `.vimrc` emit 4-space text: `py_template`, which Ctrl-T inserts, and `:FormatJson`, because `python3 -m json.tool` indents by 4 by default.
3. vim already indents by 2 (`expandtab`, `tabstop=2`, `softtabstop=2`, `shiftwidth=2`), and `.config/yapf/style` sets `indent_width = 2`.
4. clang-format in the Google style also joins the one-statement `TEST(AddTest, Negatives)` onto one line (`AllowShortFunctionsOnASingleLine`), the layout that vim's format-on-save produces from the skeleton.

### Implementation

1. `.vim/templates/gtest.cpp` takes the output of `clang-format --style=file`; `py_template` in `.vimrc` indents by 2; `:FormatJson` passes `--indent 2`; `.gitconfig`, including the tab under `[user]`, and the Containerfile indent by 2. Checks: `clang-format --dry-run --Werror` accepts `gtest.cpp`, and `make check` passes on the unmodified skeleton; the evaluated `py_template` has indent width 2 and runs; `:FormatJson` writes widths 2, 4 and 6 for three levels; `git config --list` of `.gitconfig` (17 entries) and the joined Containerfile instructions are unchanged. The two EasyEffects presets remain unchanged: they are EasyEffects data files, not authored text.
2. Merged `centos` into `centos_xps_9700` (`918cdbd`) with the script of the previous entry, which leaves the uncommitted edits of the working tree in place: `git status` and the uncommitted diff are byte-identical before and after the merge.
