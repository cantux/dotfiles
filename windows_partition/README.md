# ~/windows_partition

`~/windows_partition` is a bind mount of
`/run/media/ctuk/OS/Users/Can Tuksavul/linux_share`, a directory on the
BitLocker-encrypted Windows volume of this dual-boot Dell XPS 17 9700. It gives
Linux the free space of that volume: 365 GiB on 2026-10-26, against 44 GiB on
`/home`.

Install once, with the Windows volume unlocked and mounted in Files:

    ~/Projects/dotfiles/windows_partition/install.sh

The script asks for the sudo password. From then on, the bind mount appears
whenever the Windows volume is mounted, and disappears when it is unmounted.

Check: `findmnt /home/ctuk/windows_partition`.
Remove: `install.sh --undo`; `linux_share` and its files stay.

INSTR.md lists the checks and the debugging steps; ARCH.md describes the design
and its limits.
