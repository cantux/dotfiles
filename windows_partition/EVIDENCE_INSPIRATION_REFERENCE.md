# EVIDENCE, INSPIRATION, REFERENCE

## Primary sources (checked on this machine)

1. systemd.mount(5), systemd 257: `What=` ("If this mount is a bind mount and
   the specified path does not exist yet it is created as directory");
   `Where=` (created when missing; "This string must be reflected in the unit
   filename"); `DirectoryMode=` (default 0755).
2. systemd.unit(5), systemd 257: `BindsTo=` ("the mount point of a mount unit
   might be unmounted without involvement of the system and service manager",
   and the stronger behaviour together with `After=`); `WantedBy=` ("A
   symbolic link is created in the .wants/ … directory of each of the listed
   units when this unit is installed by systemctl enable").
3. systemd v257 source, https://github.com/systemd/systemd/blob/v257/src/core/unit.c
   (sha256 `d7acd6adb6865ed326706b5bfcad2867a4a621a7ac5774f056e2c93f0ae1a0ff`):
   - lines 2211–2230, `retroactively_start_dependencies()`: starts `Requires=`
     and `BindsTo=` units with job mode `replace` and `Wants=` units with job
     mode `fail`, unless the unit is ordered after them;
   - lines 2232–2242, `retroactively_stop_dependencies()`: stops `BoundBy=`
     units;
   - lines 2662–2671, `unit_notify()`: calls both functions when a state change
     happens "without being requested by a job".
4. systemd v257 source, https://github.com/systemd/systemd/blob/v257/src/core/mount.c
   (sha256 `9150436a997fc06d92d318f01ca7e7a0f32c1f2a1b2a8784bdd3a6027c5bf06c`),
   lines 264–294, `mount_add_mount_dependencies()`: a bind mount requires the
   mounts of its parent directory and of its source path
   (`RequiresMountsFor=`).
5. ntfs-3g(8), ntfs-3g 2026.2.25: section "Windows hibernation and fast
   restarting" ("partitions on internal disks are forced to be mounted in
   read-only mode"); options `windows_names`, `silent`, `special_files`,
   `big_writes`.
6. git-config(1): `core.fileMode`, which `git init` and `git clone` probe.
7. Microsoft, "Naming Files, Paths, and Namespaces": reserved device names,
   also when an extension follows them; no trailing space or period.
   https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file
8. mount(8), util-linux: section "Bind mount operation".

## Method

1. Trigger test (WORKLOG step 4): a user-manager unit in
   `$XDG_RUNTIME_DIR/systemd/user/`, enabled with `--runtime`;
   `rclone mount <dir> <dir> --daemon` as the external mount and
   `fusermount3 -u` as the external unmount; state read with
   `systemctl --user is-active`. The user manager runs the same systemd build
   as PID 1 and the same `unit.c`; the system manager differs in privileges,
   not in this logic.
2. Measurements (ARCH.md): a Python harness timed each operation with
   `time.perf_counter_ns()` over 10,000 operations (500 for fsync), in three
   runs interleaved between the two file systems; `/proc/diskstats` counted the
   flushes per fsync; the git timings used the 17,989-file kernel-devel tree
   without its one reserved name. The harness lived in a temporary directory
   and is not kept.

## Inspirations and parallels

1. `SYSTEMD_WANTS=` (systemd.device(5)) starts units when a device appears.
   `WantedBy=` on a mount unit applies the same pattern to a mount that another
   program creates.
2. B. K. R. Vangoor, V. Tarasov, E. Zadok, "To FUSE or Not to FUSE: Performance
   of User-Space File Systems," *15th USENIX Conference on File and Storage
   Technologies (FAST '17)*, 2017, pp. 59–72: each operation that misses the
   kernel caches costs a round trip to the user-space daemon. The measurements
   fit that model: 17,989 files × 30.0 µs per `lstat` predicts 0.54 s for
   `git status`, against 0.55 s measured.
   https://www.usenix.org/conference/fast17/technical-sessions/presentation/vangoor
