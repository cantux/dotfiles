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

### Run 1 (2026-10-26) and fix

1. The run stopped at `dnf install -y nsight-systems-cli` with `GPG check FAILED`: `dnf config-manager --add-repo` writes a repo file without `gpgkey`, `/etc/dnf/dnf.conf` sets `gpgcheck=1`, and the rpm database held no NVIDIA key. Every step before it took effect (libvirt 12.8.0, `libvirt` group, `/home/mls-pool`, kernel arguments in `/etc/kernel/cmdline`); every step after it did not run.
2. Evidence: the repository serves `nvidia.pub` (sha256 `f394a740…6515dde0`), RSA-4096 key `AE09FE4BBD223A84B2CCFCE3F60F4B3D7FA2AF80`, `cudatools <cudatools@nvidia.com>`, created 2016-06-24, SHA-256 self-signature. Both packages carry `RSA/SHA512` signatures by key ID `7fa2af80`. Imported into a temporary rpm database (`--dbpath`), the key verifies both packages under crypto policy DEFAULT (`rpmkeys --checksig`: OK); a second import returns 0.
3. Implementation: new pins `NVIDIA_DEVTOOLS_REPO` and `NVIDIA_DEVTOOLS_KEY_SHA256`; the script downloads `nvidia.pub`, checks its sha256 and runs `rpm --import` before `dnf install`. The `mktemp` work directory and its cleanup trap moved ahead of this step. The last line asks only for a reboot, because the login after the reboot has the `libvirt` group.
4. A repeated run is safe: grubby removes an argument of the same name before adding it (`/usr/sbin/grubby`, `update_args`). `--undo` leaves the key, the repository file and the installed packages in place, as it leaves libvirt installed.
5. `shellcheck` 0.11.0 clean.

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

## 2026-11-04 — Maximum output tokens per response for Claude Code

### Need

At `max` effort a single response can spend its whole output budget on reasoning. On 2026-11-04 between 18:27 and 19:08 UTC, in `~/Projects/VCLN/beejxx`, four consecutive attempts of one design response stopped with `stop_reason: max_tokens` at exactly 64000 output tokens, each attempt holding only a thinking block; the CLI gave up after its third recovery and the turn ended with no result. The first recorded occurrence on this machine was 2026-10-23 20:22–20:31 UTC in `~/Projects/VCLN/trials` (15 stops, all at 64000, model `claude-fable-5-1`), the day after the `max` effort default of 2026-10-22.

### Evidence

1. `claude` 2.1.318 (`~/.local/share/claude/versions/2.1.318`): the per-model table gives `max_output_tokens: {default: 64000, upper: 128000}` for `claude-fable-5`, `claude-opus-5-5`, `claude-mythos-5-1`, `claude-opus-4-5` through `claude-opus-4-8` and `claude-sonnet-4-6`; `claude-opus-5` and `claude-sonnet-5` hold `{default: 128000, upper: 128000}`. Models without an entry fall back to the constants `kA=32000` and `JG=128000`.
2. The same binary reads `CLAUDE_CODE_MAX_OUTPUT_TOKENS` through a parser that takes the default when the variable is unset or not a positive number, takes the value when it lies at or below the model's upper limit, and otherwise uses the upper limit with status `capped` and the log line `Capped from X to Y`. No value removes the ceiling; a request sent without streaming ignores the variable (the CLI's own error text states this).
3. The CLI's recovery loop allows three resumptions per turn (`ls=3`); each injects the message `Output token limit hit. Resume directly …`. Session transcripts under `~/.claude/projects/` record each stop with `output_tokens` and the model.

### Implementation

1. `.claude/settings.json`: added `"CLAUDE_CODE_MAX_OUTPUT_TOKENS": "128000"` to `env`, the ceiling of the current models. Carried over `"model": "claude-fable-5-1[1m]"` and `"switchModelsOnFlag": false` from the deployed file, where `/model` had written them, so that the sync restores nothing older.
2. Executed `./sync.sh`; the deployed file is byte-identical to the repository file.

### Consequences

1. Every Claude Code session of this account, subagents included, may now produce up to 128000 output tokens per response, twice the former default. A response that still exceeds it fails the same way.
2. A model whose table entry has a lower upper limit receives that limit with a `capped` status, not an error; the effective value is read from the binary, not observed in a new session.
3. Each attempt that reached 64000 tokens took about thirteen minutes; the new ceiling allows a single response to run for about twice that before it fails.

## 2026-11-06, OpenClaw model roster update

1. Moved every OpenAI-backed agent (`main` through `agents.defaults.model.primary`, `orchestrator`, `reviewer_openai`, `coolguy`, `mouse`, `hoddard`, the five `*_codex` pipeline workers) to `openai/gpt-6-astra` with thinking `max`; every Gemini-backed agent (`engineer_gemini`, `snake`, the five `*_gemini` workers) to `antigravity/gemini-4-argon-high`, the highest Antigravity effort; `engineer_claude` to `claude-cli/claude-opus-5-5`. The previous primary became the first fallback wherever a fallback list exists; allow-lists gained the new ids. 48 paths changed; `openclaw config validate` passes. Pre-change copy: `~/.openclaw/openclaw.json.bak.premodels-20261106`.
2. `openclaw config patch` and `openclaw config set --batch-file` hang indefinitely on this host, before and after a gateway restart; per-path `openclaw config set <path> <json> --strict-json [--replace]` completes in about 10 s each with a hot reload. The gateway's owner lease in `state/openclaw.sqlite` had not been renewed since 2026-11-01 while the process kept running; `openclaw gateway restart` renewed it.
3. Rewrote the Model and Fallbacks lines of the 18 affected `~/.openclaw/workspaces/*/IDENTITY.md` files by hand: `regen_souls.py` went away with `~/Projects/llm_serving` on 2026-10-27. Refreshed `openclaw/openclaw.json` with `bin/snapshot-openclaw`. Not committed.

## 2026-11-06, OpenClaw Fable on the design stage

1. `designer_fable_5_1`, `design_experimenter_evaluator_fable_5_1` and `implementation_merger_fable_5_1` moved to `claude-cli/claude-fable-5-1`; fallbacks `claude-cli/claude-opus-5-5`, `claude-cli/claude-sonnet-5-5`, `antigravity/claude-opus-5-5-high`, `antigravity/claude-sonnet-5-5-high`. Manager, researcher and implementor stay on Opus 5.5. Basis: the per-step usage in `~/Projects/ai/cloud_inference_provider/evidence/openclaw_phases.md` (phase 4 holds 45% of run-004's output tokens, phase 3 holds 3%). Six per-path `config set` writes; the three IDENTITY.md files rewritten; snapshot refreshed. Not committed.

## 2026-11-06, OpenClaw role files under dotfiles

1. Need: the pipeline's role files existed only in `~/.openclaw/workspaces/`, and the generators that produced them were deleted on 2026-10-27 with `~/Projects/llm_serving`; the findings of the pipeline review had no file at all.
2. `bin/sync-openclaw-workspaces` (new): copies `SOUL.md` and `IDENTITY.md` per workspace between `openclaw/workspaces/<agent>/` and `~/.openclaw/workspaces/<agent>/`. Modes: `apply` (repository to live, the default), `import` (live to repository), `diff` (unified diff per file, then every live workspace the repository lacks). It copies only files whose content differs and deletes nothing. `sync.sh` runs it before `bin/sync-openclaw-baseline` whenever `~/.openclaw` exists (the guard was `~/.openclaw/workspaces`, which a restore does not have yet) and copies the script to `~/bin`.
3. Executed `import`: 70 files from 35 workspaces (35 `SOUL.md`, 35 `IDENTITY.md`; the secret regex of `bin/snapshot-openclaw` matches nothing in them). `diff` reports identical, `apply` wrote 0 of 70, and `cmp` per file confirms byte identity. `bash -n` passes on the script and on `sync.sh`. `shellcheck` is not installed on this host at present, and this session was not permitted to fetch `shellcheck-py` through pipx; the script is unlinted.
4. `openclaw/ISSUES.md` (new): the ten findings of the pipeline review, with every term introduced before it is used. Two coined names of the previous draft are gone: the fourth round of phase 4 is called "round 4 of phase 4", and the plan step that opens phases 4 and 5 is called "the planning step of phase 4" and "of phase 5". Two reviewer subagents checked the file, one for "every term introduced before it is used" and one for "every sentence adds a fact"; their first reports gave six findings each (title and preamble, terms 6, 7, 16, 17 and 25, finding 2, finding 9), one rebuild answered all twelve, and both re-checks pass with zero findings.
5. `openclaw/NOTES.md`: the tracked set, the sync direction (the repository overwrites the live role files; run `import` after `openclaw agents add` or after an agent rewrites its own file), and restore step 5 is now `./sync.sh`. `README.md`, "What's tracked": one paragraph on the two OpenClaw hooks. Not committed.

## 2026-11-06, OpenClaw second pipeline

1. Need: the author asked for a parallel pipeline that implements the fixes of `openclaw/ISSUES.md`, section C, with the first pipeline left as it is.
2. `openclaw/gen_roles.py` (new): one table of sixteen agents (`pipeline_manager_v2` and fifteen `*_v2` workers; the model profiles of the first pipeline) and one template per role; it writes `openclaw/workspaces/<agent>/SOUL.md` and `IDENTITY.md` and prints the configuration entries with `--config`. The templates derive from the first pipeline's role files (identical across families after normalising the family name) with the fixes applied; they name no technology and take task specifics from the clarified task. Sixteen workspaces, 32 files; `yapf` clean.
3. Configuration: sixteen `agents.entries.*` written with per-path `config set --replace`. The first pass accepted the five codex entries and refused eleven: every `antigravity/` model reference was reported unresolvable while the gateway slowed from 41 s to 161 s per write and `openclaw models list` timed out. After `openclaw gateway restart` the eleven were accepted unchanged (194 s). `openclaw config validate` passes; the live entries equal the generator's output; `openclaw agents list` shows all sixteen. Snapshot refreshed with `bin/snapshot-openclaw`.
4. Workspaces: `bin/sync-openclaw-workspaces apply` created the sixteen live workspaces (32 files written, 102 tracked); `bin/sync-openclaw-baseline` embedded the baseline into 51 `AGENTS.md` files. OpenClaw seeded `USER.md` into `pipeline_manager_v2` on its first session.
5. `~/Projects/openclaw_pipeline/` (new, its own git repository, nothing committed): `tools/probe_host.sh`, `tools/verify_phase.sh`, `tools/closure_ledger.py` with `tools/test_closure_ledger.py`, `tools/run_pipeline.sh`, `runs/` (ignored), and README, MAP, ARCH, INSTR, WORKLOG and evidence files. The probe ran in 17 s on this host and records the refused BPF mount; the verifier detects missing files and changed markers; the ledger's two tests pass; the driver is syntax-checked only.
6. Smoke test: `openclaw agent --agent pipeline_manager_v2 --session-key agent:pipeline_manager_v2:smoke-20261106 -m "identity probe: ..."` answered `pipeline_manager_v2: claude-cli/claude-opus-5-5 claude-cli`.
7. `openclaw/ISSUES.md` gained sections C (the suggested fixes) and D (this implementation); `openclaw/NOTES.md` describes the generator and the second pipeline. Not done: the gemini family's route change (fix 8) and the OpenAI login (fix 10), both the author's decisions; no run started. `shellcheck` remains unavailable. Not committed.

## OpenClaw gateway drop-in and the dry run of the second pipeline (2026-11-06)

1. `.config/systemd/user/openclaw-gateway.service.d/override.conf` (new, in `sync.sh`): `Environment=CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`. Reason: the manager of the second pipeline, on the Claude runtime, wrote notes into Claude Code's auto-memory of its working folder `~/Projects/openclaw_pipeline`, which every Claude-runtime agent with that folder loads at session start, across roles and runs. Applied by `./sync.sh`, then `systemctl --user daemon-reload && openclaw gateway restart`.
2. `openclaw/NOTES.md` restore steps 8 and 9: the Antigravity project roots the plugin requires (the gemini family failed every probe of the dry run because `~/Projects/openclaw_pipeline` lies outside them), and the drop-in. `openclaw/ISSUES.md` section D records both findings.
3. Not applied by the assistant: the edit of `~/.gemini/config/projects/749a726c-e771-4b76-a646-3e0171617650.json` (the classifier denies a widening of a trust boundary); the operator applies it from the prepared copy.

## Memory flush disabled for the OpenClaw gateway (2026-11-07)

1. Finding: the pre-compaction memory flush of OpenClaw ran a hidden turn on `openai/gpt-6-astra` over 262 528 uncached context tokens when the `codex` evaluator of the second pipeline reached 265 278 of its 272k context tokens; it cost 9 points of the OpenAI 5-hour window and tried to write a memory file outside the run directory (`openclaw/ISSUES.md`, section D).
2. Change: `openclaw config set agents.defaults.compaction.memoryFlush.enabled false --strict-json` on the live gateway (hot reload), `bin/snapshot-openclaw` refreshed `openclaw/openclaw.json`, restore step 10 added to `openclaw/NOTES.md`.
3. Not committed; the user decides on the commit.

## Unsupervised operation of the second pipeline (2026-11-07)

1. `openclaw/gen_roles.py`: the manager template gained limits rules, operator levers, the `# WAITING` heading and the phase-5 rule for a family without a design; the worker contract gained item 14 (resume from partial outputs). Regenerated 16 role files under `openclaw/workspaces/` and applied them with `./sync.sh` at 12:35 PST.
2. `openclaw/ISSUES.md` section F records the observed stops, the measurements and the mechanisms; the tools live in `~/Projects/openclaw_pipeline/tools/`.
3. Not committed; the user decides on the commit.
4. Found the eighteen OpenClaw automations on OpenAI-backed agents (ISSUES.md section F item 4); the pipeline's `tools/openai_automations.sh` disables and re-enables them, run by the user.
5. `skills.workshop.autonomous.mode` set to `propose` on the live gateway (18:20 PST) after `cron disable` proved ineffective on system-owned jobs; snapshot refreshed; restore step 11 in `openclaw/NOTES.md`.

## OpenClaw gateway on demand (2026-11-10)

1. Finding: idle, the gateway (`openclaw-gateway.service`, running since 2026-11-06 23:10 PST) held 3.4 GiB PSS, the largest share of the 13.1 GiB in use; systemd reported a 14.4 GiB memory peak (cgroup `memory.peak`, file cache included) and 8 h 32 min of CPU time.
2. Decision (user): the gateway runs only while OpenClaw work is in progress.
3. `openclaw/NOTES.md`: new section "Gateway on demand" (start, stop and restart through `systemctl --user`); restore step 12 (autostart off); steps 8 and 9 restart through `systemctl --user`, because OpenClaw's `gateway stop|restart` treat a disabled unit as not loaded.
4. Applied at 13:30 PST, after a guard found no client connection on port 18789 and no agent process in the unit's cgroup: `systemctl --user disable --now openclaw-gateway.service` removed the `default.target.wants` link; the gateway logged a clean shutdown and stopped in 2 s. Verified: `is-enabled` disabled, `is-active` inactive, no listener on 18789, no reverse dependency, no gateway process; MemAvailable rose from 15.8 to 19.2 GiB.
5. Not committed; the user decides on the commit.

## sync.sh enforces the gateway's autostart policy (2026-11-10)

1. Dry run of `sync.sh` (`cmp` per file, `rsync -a --delete -n -i -c` per directory, `bin/sync-openclaw-workspaces diff`, a simulation of `bin/sync-openclaw-baseline`): 24 of 25 targets equal, role files identical, 0 of 51 `AGENTS.md` changed. The single difference: `~/.claude/settings.json`, changed live on 2026-11-10 at 13:32, while the repository copy dates from 2026-11-04; as parsed JSON the two differ only in `model` (repository `claude-fable-5-1[1m]`, live `opus`). A run copies the repository value over the live one, so the assistant did not run `./sync.sh`.
2. `sync.sh`: when `~/.config/systemd/user/openclaw-gateway.service` exists, the OpenClaw block runs `systemctl --user disable openclaw-gateway.service`, so every sync reverts the autostart that `openclaw gateway install` turns on.
3. `openclaw/NOTES.md` (restore step 12, section "Gateway on demand") and `README.md` (OpenClaw paragraph) describe the step.
4. Verified: `bash -n sync.sh`; the step, cut from `sync.sh`, ran after `systemctl --user enable openclaw-gateway.service`: run 1 removed the `default.target.wants` link (exit 0), run 2 changed nothing (exit 0); the gateway stayed inactive. `shellcheck` is not installed.
5. Open: the `model` value in `.claude/settings.json`, the user's decision. Not committed.

## Claude Code default model: Fable 5.2 (2026-11-10)

1. Decision (user): the default model is Claude Fable 5.2.
2. `.claude/settings.json`: `model` changed from `claude-fable-5-1[1m]` to `claude-fable-5-2[1m]`. Anthropic's model table (claude-api skill, cached 2026-11-03) lists `claude-fable-5-2` with a 1M context window, which is also its default. The Claude Code 2.1.322 binary contains the ID and the help text "append [1m] to the model name for 1M", so the suffix keeps the earlier choice of a 1M window explicit.
3. Dry run before the sync: only `.claude/settings.json` differed (the live file held `opus`, set at 13:32 outside the repository). `./sync.sh` exited 0: 0 of 102 role files written, 51 `AGENTS.md` rewritten with identical content, the gateway step found the unit already disabled. Dry run after the sync: every target equal; the live `model` reads `claude-fable-5-2[1m]`.
4. Not committed; the user decides on the commit.

## Claude Code effort: `max` as the starting level, changeable with `/effort` (2026-11-11)

1. Need (user): `max` stays the default effort, and `/effort` changes the level of a running session without a restart. `/effort xhigh` had answered `CLAUDE_CODE_EFFORT_LEVEL=max overrides this session — clear it and xhigh takes over`; a restart with `claude --resume` (22:17:30 PST) changed nothing.
2. Finding: no bash file sets the variable. `.claude/settings.json` set it through `env` (entry of 2026-10-22); the start environment of the session process (`/proc/<pid>/environ`) does not contain it, so every restart read it again from the settings.
3. Evidence from the 2.1.322 binary (`EVIDENCE_INSPIRATION_REFERENCE.md`, 2026-11-11): the variable ranks above the session level; `--effort <level>` initializes the session level, the state that `/effort` replaces; the settings schema still limits `effortLevel` to `low`, `medium`, `high`, `xhigh`.
4. Change:
   - `.claude/settings.json`: removed `env.CLAUDE_CODE_EFFORT_LEVEL`; carried over `modelSettings.claude-fable-5-2.effortLevel = "xhigh"`, which `/effort xhigh` had written to the live file at 22:16.
   - `.bash_aliases`: `claude() { command claude --effort max "$@"; }`. A function and not an alias: `cmax` and `ccw` call `claude` at execution time, whereas bash expands an alias inside `ccw` only when the alias precedes the function definition.
5. Dry run before the sync: of the `sync.sh` targets only `.claude/settings.json` differed from `$HOME`, as parsed JSON in `modelSettings.claude-fable-5-2.effortLevel` alone. `./sync.sh` exited 0 in each of three runs between 22:24 and 22:27 PST (0 of 102 role files written, 51 `AGENTS.md` rewritten, gateway unit already disabled).
6. Sessions already running: the settings watcher assigns `env` values to the process and does not remove a deleted key; at 22:26:27, after the first sync, the tool shell of the running session still held `CLAUDE_CODE_EFFORT_LEVEL=max`. A second sync with `"CLAUDE_CODE_EFFORT_LEVEL": ""` (22:27:02) released the override within 3 s: the tool shell held the empty value and `CLAUDE_EFFORT=xhigh`. The binary treats the empty string as no override. A third sync (22:27:22) removed the key; the running session stayed released. Three sessions ran at that time (pids 3538518, 4118726, 4124369); the assistant observed 4124369 only.
7. Verified with `claude -p "/effort <argument>"` in shells started by `env -i … bash -ic`. The command answers without a model request and, in print mode, writes no settings: the md5 of the live settings file was equal before and after each group of probes.

   | Probe | Before | After |
   |---|---|---|
   | `claude`, `/effort status` | `max` | `max` (through the function) |
   | `claude --effort low`, `/effort status` | `max` | `low` |
   | `claude`, `/effort xhigh` | the override message | `Set effort level to xhigh (this session only)` |
   | `command claude`, `/effort status` | `max` | `xhigh` (persisted level) |
   | `CLAUDE_CODE_EFFORT_LEVEL= command claude`, `/effort high` | not measured | `Set effort level to high (this session only)` |

8. Consequences:
   - A session that does not start through the function (script, systemd unit, `command claude`) starts at the persisted level, at most `xhigh`. This reverses consequence 3 of 2026-10-22 for such sessions.
   - In an interactive session `/effort <level>` other than `max` also saves the level as the persisted default (`modelSettings.<model>.effortLevel` in the live `settings.json`), so the live file then differs from the repository copy; sessions started through the function are not affected.
   - A subagent without its own `effort` inherits the session level, so it follows `/effort`.
   - `CLAUDE_CODE_EFFORT_LEVEL=<level> claude` still pins one session, as before.
9. Not committed; the user decides on the commit.

## clangd: C files get `-std=gnu11` (2026-11-11)

1. Finding: the user configuration added `-std=c++20` to every file. For `~/Projects/epi/cxx/linked_list/bootcamp/linked_list.c`, `clangd --check` (22.1.8) reported `invalid argument '-std=c++20' not allowed with 'C'` and, after it, `cannot initialize a variable of type 'Node *' with an rvalue of type 'void *'`.
2. Change: `.config/clangd/config.yaml` keeps `-Wall -Wextra` and the clang-tidy set for every file. A second fragment adds `-std=c++20` to every path except `.*\.c`; a third adds `-std=gnu11` to `.*\.c`.
3. Verified with `clangd --check`, first against a candidate under a scratch `XDG_CONFIG_HOME`, then live after `./sync.sh` (exit 0; a dry run before it found every other target equal to `$HOME`): `linked_list.c` parses with `-std=gnu11` and no error; five `.cpp` files and a probe header that includes `<span>` keep `-std=c++20` and their earlier results.
4. The change does not depend on the machine, so it belongs on branch `centos` at commit time. Not committed; the user decides on the commit.

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
3. Deployed `.vim` with the `rsync` command of `sync.sh`, whose dry run listed only `templates/gtest.cpp`, and copied `.vimrc` and `.gitconfig` as `sync.sh` does, after confirming that the deployed copies equalled the pre-change repo versions. The deployed files equal the repo; git reads the deployed `.gitconfig`, and vim with the deployed `.vimrc` defines the 2-space `py_template`. Skipped the full `sync.sh` for the reason that the previous entry records.

### Consequences

1. A skeleton that `,ut` inserts passes `make format-check` without a reformat.
2. Ctrl-T inserts a 2-space Python skeleton, and `:FormatJson` writes 2-space JSON.
3. The two EasyEffects presets keep their 4-space indentation.

## 2026-11-26 — Consolidation of system drift and uncommitted work

1. Request: "find changes from the system, consolidate and push". Of the 22 paths that `sync.sh` deploys and the three copies of the agent instructions, only `.claude/settings.json` and `.codex/config.toml` differed from the repository: Claude Code rewrote the first on 2026-11-23 (model `opus`, effort `xhigh` for `claude-opus-5-5`, keys reordered), Codex the second on 2026-11-24 (model `gpt-6.1-sol`, trusted projects `ai`, `ai/kubernetes` and `forum`). The repository now holds the system's copies, so a later `./sync.sh` keeps them.
2. The working tree of `centos_xps_9700` held work since October that had been deployed but not committed. Placement rule: a file identical on `centos` and `centos_xps_9700` goes to `centos`, then `centos` merges into `centos_xps_9700`. Four commits on `centos`, made in a separate worktree: the two settings files; `.bash_aliases`, the clangd configuration and `install_llm_cluster_host.sh`; the OpenClaw role files, `bin/sync-openclaw-workspaces`, the gateway override and the OpenClaw parts of `sync.sh` and `README.md`; this log and the evidence file. `heroic/` and its README section serve this machine's games and went to `centos_xps_9700`.
3. Checks before the commits: no credential in any committed file (pattern scan; the OpenClaw gateway token is the placeholder `REDACTED` that `bin/snapshot-openclaw` writes). After the merge, every path that `sync.sh` deploys equals its copy under `$HOME`, so no `./sync.sh` run was needed.
4. `centos` and `centos_xps_9700` pushed to `origin` over HTTPS, because SSH to github.com stalls on this machine.
