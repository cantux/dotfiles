# INSTR

## Install

1. Unlock and mount the Windows volume in Files (entry "OS");
   `findmnt /run/media/ctuk/OS` prints it.
2. Run `~/Projects/dotfiles/windows_partition/install.sh`. It asks for the sudo
   password, then:
   1. copies the unit to `/etc/systemd/system/` and reloads systemd;
   2. enables the unit, which links it into `run-media-ctuk-OS.mount.wants/`;
   3. creates `linux_share` if it is missing, and starts the bind mount.

A repeated run leaves the system as the first run left it.

## Verify

1. `findmnt /home/ctuk/windows_partition`: SOURCE ends with
   `[/Users/Can Tuksavul/linux_share]`, FSTYPE is `fuseblk`.
2. `systemctl show -p Wants -p BoundBy run-media-ctuk-OS.mount`: both list
   `home-ctuk-windows_partition.mount`.
3. `touch ~/windows_partition/probe && ls "/run/media/ctuk/OS/Users/Can Tuksavul/linux_share/" && rm ~/windows_partition/probe`:
   the listing shows `probe`.
4. Trigger: unmount the volume in Files; `findmnt /home/ctuk/windows_partition`
   prints nothing. Mount the volume again; the bind mount returns.

## Use

1. `df -h ~/windows_partition` shows the free space, which Windows shares.
2. Large files (datasets, model weights, archives, disk images) suit the mount.
   Trees of many small files (sources, build output, git working trees) cost 6
   to 24 times more per operation than on `/home`.
3. Names that Windows reserves fail with `EINVAL`: `CON`, `PRN`, `AUX`, `NUL`,
   `COM1`–`COM9`, `LPT1`–`LPT9`, also with an extension; names that end in a
   space or a period; names that contain `" * : < > ? \ |`.

## Debug

1. Volume mounted, bind mount absent:
   `systemctl status home-ctuk-windows_partition.mount`,
   `journalctl -b -u home-ctuk-windows_partition.mount`, and
   `ls -l /etc/systemd/system/run-media-ctuk-OS.mount.wants/` for the link.
2. Volume mounted read-only: Windows hibernated or has Fast Startup on, and
   ntfs-3g then forces read-only mode (ntfs-3g(8)). In Windows, run
   `powercfg /h off` as Administrator, then shut down.
3. Locking the volume fails as busy: a process still uses the bind mount.
   `fuser -vm /home/ctuk/windows_partition` names it; after it exits,
   `sudo systemctl stop home-ctuk-windows_partition.mount`.

## Undo

`~/Projects/dotfiles/windows_partition/install.sh --undo` disables and stops
the unit, deletes it from `/etc/systemd/system/`, reloads systemd, and removes
the empty mount point. It keeps `linux_share` and its files.
