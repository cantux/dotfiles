# ARCH

## Terms

- *Windows volume*: the NTFS file system on `nvme0n1p3`, mounted at
  `/run/media/ctuk/OS`.
- *Volume mount unit*: `run-media-ctuk-OS.mount`, the unit that systemd
  synthesizes from `/proc/self/mountinfo` when udisks2 mounts the Windows
  volume.
- *Bind unit*: `home-ctuk-windows_partition.mount`, the unit in this directory.

## Layers

From the drive to the mount point (observed 2026-10-26 with `lsblk`, `findmnt`
and `ps`):

1. `nvme0n1p3` (741.4 GiB, BitLocker version 2) on the Samsung PM981a that also
   holds CentOS (`nvme0n1p8`, LVM, XFS).
2. `/dev/mapper/bitlk-…`: the dm-crypt mapping that udisks2 opens when the user
   unlocks the volume in Files.
3. NTFS, served by ntfs-3g 2026.2.25 through FUSE (`fuseblk`) in one thread,
   with the udisks2 options `uid=1000,gid=1000,windows_names`. Kernel
   6.12.0-271.el10 has no ntfs3 driver (`CONFIG_NTFS3_FS` unset).
4. The bind mount of `Users/Can Tuksavul/linux_share` at
   `/home/ctuk/windows_partition`.

## Trigger

udisks2 mounts the Windows volume only after an interactive unlock, so no
boot-time unit can mount the bind. The bind unit follows the volume mount unit
instead.

1. `WantedBy=run-media-ctuk-OS.mount`: `systemctl enable` links the bind unit
   into `run-media-ctuk-OS.mount.wants/`, and systemd reads that directory when
   it loads the volume mount unit.
2. When udisks2 mounts the volume, the volume mount unit becomes active without
   a job. `unit_notify()` then calls `retroactively_start_dependencies()`,
   which starts its `Wants=` units (systemd v257, `src/core/unit.c`).
3. `BindsTo=` with `After=`: when udisks2 unmounts the volume, the volume mount
   unit becomes inactive without a job, and systemd stops the bind unit
   (systemd.unit(5)).
4. No unit pulls the bind unit in at boot, so a boot without the unlocked
   volume records no failure.

## Invariants

1. The unit file name equals the escaped `Where=` path:
   `systemd-escape -p --suffix=mount /home/ctuk/windows_partition`.
2. `What=` holds the space of `Can Tuksavul` literally; systemd parses the
   value as one path.
3. `install.sh` never deletes `linux_share` or its files.
4. While the volume is absent, `~/windows_partition` is an empty directory
   owned by root, so a write there fails and does not fill `/home`.

## Trade-offs

1. Bind mount over a symbolic link: programs see `/home/ctuk/windows_partition/…`,
   a path without a space even after they resolve links. The cost is one
   `sudo` at installation.
2. Unit file over `/etc/fstab`: fstab cannot order a mount after a udisks2
   mount. A boot-time mount would need a `crypttab` entry (`bitlk`) and a
   passphrase prompt at every boot.
3. Directory on NTFS over a new XFS logical volume: no repartitioning, at the
   cost below.

## Measured cost

NTFS through ntfs-3g against XFS (`cs-root`) on the same drive, 2026-10-26.
Three interleaved runs; each cell is the median of the three per-run medians
(p50).

| Operation | Windows volume | XFS | Ratio |
|---|---|---|---|
| create + 4 KiB write + close | 107 µs | 17.2 µs | 6.2 |
| lstat | 30.0 µs | 1.6 µs | 19 |
| rename | 104 µs | 5.2 µs | 20 |
| unlink | 56.3 µs | 5.1 µs | 11 |
| sequential write, 1 GiB, until fsync returns | 136 MiB/s | 2,468 MiB/s | 18 |
| sequential read, uncached (different files) | 1,634 MiB/s | 2,046 MiB/s | 1.25 |
| `git status`, 17,989 files | 0.55 s | 0.023 s | 24 |
| speedup of 8,000 creates from 1 to 8 processes | 1.8× | 5.0× | — |

## Semantics

1. `chmod` succeeds and changes nothing; every file has mode 777 (ntfs-3g
   `silent`), and git sets `core.fileMode=false`.
2. Names that Windows reserves fail with `EINVAL` (`windows_names`);
   `include/soc/arc/aux.h` stopped a checkout of the kernel tree.
3. Names that differ only in case coexist; symbolic links, hard links, FIFOs,
   `user.*` extended attributes and `flock` work. Windows cannot use the
   case-only pairs or the Interix-format links. Windows interoperability is
   not a goal.
