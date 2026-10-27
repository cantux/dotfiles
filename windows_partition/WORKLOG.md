# WORKLOG

2026-10-26

1. The user asked whether a directory on the Windows volume can hold a Linux
   project, at what latency, on which file system, and with how much free
   space. Measured NTFS through ntfs-3g against XFS on the same drive (method
   in EVIDENCE_INSPIRATION_REFERENCE.md, results in ARCH.md). Outcome: NTFS
   inside BitLocker, served by ntfs-3g through FUSE; 365 GiB free; file
   operations cost 6 to 24 times as much as on XFS; chmod has no effect; the
   reserved name `include/soc/arc/aux.h` stopped a checkout of the kernel tree.
2. The user needs no Windows interoperability and asked for `linux_share` under
   the Windows profile, mounted at `~/windows_partition`. Created
   `/run/media/ctuk/OS/Users/Can Tuksavul/linux_share`; ntfs-3g reports owner
   `ctuk`, mode 777, type `fuseblk`.
3. Decision: a systemd bind-mount unit that follows the volume mount unit
   (ARCH.md, sections Trigger and Trade-offs). udisks2 mounts the volume only
   after an interactive unlock, and `/etc/fstab` cannot order a mount after
   that.
4. Verified the trigger without root in the user manager, which runs the same
   build as PID 1 (systemd 257-34.el10). A oneshot probe with `BindsTo=`,
   `After=` and `WantedBy=` on the mount unit of an `rclone mount` FUSE mount
   became active when the mount appeared and inactive after `fusermount3 -u`.
   Control: the same probe without the `.wants/` link stayed inactive after the
   mount, and the mount unit listed no `Wants=`.
5. Checked the unit file. Loaded in the user manager, it parses to
   `What=/run/media/ctuk/OS/Users/Can Tuksavul/linux_share` with the space
   intact, `BindsTo=run-media-ctuk-OS.mount`, and the implicit
   `RequiresMountsFor=` on the source path and on `/home/ctuk`.
   `systemd-analyze verify` reports no parse error; it cannot build a start
   job, because its test manager does not see the live volume mount unit.
   `shellcheck` 0.11.0 reports nothing on `install.sh`.
6. Branches: committed on `centos` a note in `CLAUDE.md` and `README.md` that
   names `centos_xps_9700`; created `centos_xps_9700` from that commit;
   committed on it this directory, the section "Additional storage" and the
   branch name in `CLAUDE.md`, the branch of this machine in
   `.claude/CLAUDE.md`, and a pointer in `README.md`.
7. Applied the changed files to `$HOME` with the copies that `sync.sh` makes:
   `CLAUDE.md` to `~/CLAUDE.md` and `~/AGENTS.md`; `.claude/CLAUDE.md` to
   `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md` and
   `~/.gemini/config/rules/GEMINI.md`; `bin/sync-openclaw-baseline` embedded
   the new baseline in 35 workspace `AGENTS.md` files. `sync.sh` itself did
   not run: `~/.claude/settings.json` holds `"model": "fable"`, the repository
   `"model": "sonnet"`, and a sync would overwrite the deployed value.
8. Pending: `install.sh` needs the sudo password, so the user runs it. Nothing
   is pushed.
