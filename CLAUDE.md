# System config changes

If there is any change to be made at the environment,
it should first be made at the ~/Projects/dotfiles directory.
This machine's is a CentOS Stream 10 and has a corresponding branch at the dotfiles project called centos_xps_9700

Branch centos_xps_9700 derives from centos and holds the configuration specific to the Dell XPS 17 9700 (`cat /sys/class/dmi/id/product_name` prints `XPS 17 9700`).
On that machine, make changes on centos_xps_9700; make a change that every CentOS machine needs on centos, then merge centos into centos_xps_9700.

# Additional storage

When a task needs more space than `df -h /home` reports, use `~/windows_partition`: a bind mount of `/run/media/ctuk/OS/Users/Can Tuksavul/linux_share` on the Windows NTFS volume (365 GiB free on 2026-10-26; `df -h ~/windows_partition`).
`~/Projects/dotfiles/windows_partition/` installs and documents it.

1. The mount exists only while the Windows volume is unlocked and mounted at `/run/media/ctuk/OS`; otherwise `findmnt ~/windows_partition` prints nothing. Ask the user to unlock the volume in Files.
2. ntfs-3g serves the volume through FUSE in one thread: a file operation costs 6 to 24 times as much as on `/home`, and sequential writes reach about 140 MiB/s (measured 2026-10-26). Put large files there: datasets, model weights, archives, disk images. Keep source trees, build directories and git working trees on `/home` while it has space.
3. `chmod` succeeds without effect: every file has mode 777, and git sets `core.fileMode=false`.
4. Names that Windows reserves fail with `EINVAL`: `CON`, `PRN`, `AUX`, `NUL`, `COM1`–`COM9`, `LPT1`–`LPT9`, also with an extension (`aux.h`); names that end in a space or a period; names that contain `" * : < > ? \ |`.
5. A read-only mount means that Windows hibernated or has Fast Startup on; `powercfg /h off` in Windows turns both off.
