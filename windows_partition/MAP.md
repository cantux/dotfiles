# MAP

Root of this work: `~/Projects/dotfiles`, branch `centos_xps_9700`, derived
from `centos`. This directory holds the mount unit, its installer and the
documentation.

## Components

| Path (repo-relative) | Role |
|---|---|
| `windows_partition/home-ctuk-windows_partition.mount` | systemd mount unit. Binds `linux_share` to `/home/ctuk/windows_partition` while the Windows volume is mounted. |
| `windows_partition/install.sh` | Copies the unit to `/etc/systemd/system/`, enables it, and starts it when the volume is mounted; `--undo` reverses these steps. |
| `windows_partition/README.md` | Entry point. |
| `windows_partition/ARCH.md` | Terms, layers, trigger, invariants, trade-offs, measured cost, semantics. |
| `windows_partition/INSTR.md` | Install, verify, use, debug, undo. |
| `windows_partition/WORKLOG.md` | Chronological record. |
| `windows_partition/EVIDENCE_INSPIRATION_REFERENCE.md` | Sources and method. |
| `CLAUDE.md`, section "Additional storage" | Tells agents when to use the mount and what it cannot do; `sync.sh` deploys it as `~/CLAUDE.md` and `~/AGENTS.md`. |
| `.claude/CLAUDE.md`, section "Environment updates" | Names `centos_xps_9700` as the branch of this machine. |
| `README.md`, section "Dell XPS 17 9700" | Points here. |

## Live locations

| Path | Created by |
|---|---|
| `/etc/systemd/system/home-ctuk-windows_partition.mount` | `install.sh` (copy of the unit) |
| `/etc/systemd/system/run-media-ctuk-OS.mount.wants/home-ctuk-windows_partition.mount` | `systemctl enable` (symbolic link) |
| `/home/ctuk/windows_partition` | systemd at the first mount (mount point; owner root, mode 0755) |
| `/run/media/ctuk/OS/Users/Can Tuksavul/linux_share` | `mkdir`, 2026-10-26 (the data) |

## Branch relation

`centos` names `centos_xps_9700` in `CLAUDE.md` and `README.md`. A change for
every CentOS machine goes to `centos`; `centos_xps_9700` then merges `centos`.
