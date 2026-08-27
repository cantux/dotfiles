# Environment defaults

- OS: CentOS Stream 10 (`el10`, x86_64), package manager `dnf` with EPEL + CRB enabled
- Shell: system bash (`/bin/bash`)
- Access: headless server over SSH (no local GUI)
- Multiplexer: tmux (sessions); clipboard yank uses OSC52 so copy works over SSH
- This repo: tracked dotfiles copied into `$HOME` by `sync.sh` (`.bashrc`, `.vimrc`, `.vim`, the `.claude/` and `.config/` files, etc. — see README "What's tracked" for the full list)
- Working branch: `centos` (CentOS port of the `mac` branch)

# Antigravity (agy) Workstyle & Rules

1. **Preserve Existing Files**: Never mutate or overwrite existing codebase files directly unless explicitly told. When adding new modules, companion exercises, or scratch work, create a separate subdirectory called `agy/` (e.g., `dist/agy/`) and organize additions there.
2. **Standard Documentation Hierarchy**:
   - **`MAP.md`**: Master layout and index describing where everything is, what each component does, and its role in the grand scheme.
   - **`WORKLOG.md`**: Chronological log recording the sequence of steps, decisions, test results, and sessions taken by the user and agent.
   - **`README.md`**: Architectural design, concepts, invariants, and trade-offs for each specific program/exercise.
   - **`INSTR.md`**: Explicit compilation, execution, testing, and debugging instructions.
3. **Companion & Interactive Pair-Programming**:
   - Act as an active, communicative technical companion.
   - Walk step-by-step through topics: GTest ramp-up, C++ coding drills, Linux observability & profiling internals, and concurrency/lock-free programming.
   - Combine high-level systems intuition with low-level kernel/hardware reality (MESI cache coherence, `perf_event_open`, eBPF, memory barriers, atomic operations).

# Workflow

- After editing any tracked dotfile in this repo, run `./sync.sh` to copy it into `$HOME`. Edits here do not take effect until synced — `sync.sh` does `cp`/`rsync`, not symlinks.
- For live-reloading after sync: `source ~/.bashrc` for shell changes, `tmux source-file ~/.tmux.conf` for tmux, `:source $MYVIMRC` inside vim.
