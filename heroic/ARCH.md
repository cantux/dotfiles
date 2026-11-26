# ARCH

## Terms

1. AppImage: one executable file that holds an application, its libraries and
   a runtime that mounts them. Each AppImage targets one CPU architecture.
2. Flatpak runtime: a versioned set of libraries that a sandboxed application
   runs against instead of the host libraries; here `org.freedesktop.Platform`
   26.08.
3. Runtime extension: an add-on to a runtime that Flatpak mounts into the
   sandbox. `Compat.i386` supplies 32-bit libraries, `GL32.*` supplies 32-bit
   graphics drivers, and `GL.nvidia-<version>` and `GL32.nvidia-<version>`
   supply the NVIDIA userspace driver of one exact version.
4. i686, i386: the 32-bit x86 architecture. Wine and Proton use 32-bit
   libraries for 32-bit Windows programs.

## Failure of the first installation (2026-11-14)

1. The host CPU is `x86_64` (`uname -m`).
2. The installed file `Heroic-2.22.4-linux-arm64_<hash>.AppImage` is an
   `ELF 64-bit LSB executable, ARM aarch64` (`file`). Its SHA-256,
   `a637b2a1…e58e`, equals the digest of the release asset
   `Heroic-2.22.4-linux-arm64.AppImage`.
3. The kernel refuses to execute an ELF file for a foreign architecture with
   `ENOEXEC`. AppImageLauncher's binfmt handler reports it as
   `failed to execute patched runtime: Exec format error`.
4. The desktop entry runs the same file, so a click on the icon fails before
   any window exists.

## Choice among the x86_64 channels

| Channel | 32-bit libraries for Wine and Proton | NVIDIA userspace driver | Updates |
|---|---|---|---|
| Flatpak (chosen) | runtime extensions `Compat.i386`, `GL32.default`, `GL32.nvidia-620-70-06` | `GL.nvidia-620-70-06`, selected by Flatpak to match the kernel module | `flatpak update` |
| x86_64 AppImage | from the host | from the host | self-update |
| x86_64 RPM | from the host | from the host | manual download |

The host column decides the choice. The enabled repositories of this
CentOS Stream 10 host offer 0 i686 packages (`dnf repoquery --arch i686`),
because RHEL 10 removed the 32-bit multilib packages. The AppImage and the RPM
therefore have no 32-bit graphics driver to give a 32-bit game. The Flatpak
brings its own.

## Invariants

1. The version in `GL.nvidia-<version>` equals the version of the loaded
   `nvidia` kernel module (`/proc/driver/nvidia/version`), on 2026-11-14
   620.70.06. After a driver upgrade, `flatpak update --user` installs the
   matching extension; until then the sandbox has no NVIDIA userspace driver.
2. The sandbox sees only the paths it is granted. The grants include
   `~/Games/Heroic`, `/run/media`, `/mnt` and `/media`. They exclude
   `~/windows_partition`.

## Trade-offs

1. Disk: the runtime, the extensions and the application took 4 GiB of
   `/home`; 14 GiB remained free on 2026-11-14.
2. Game storage: games larger than the free space of `/home` need the Windows
   volume. The sandbox reaches it through
   `/run/media/ctuk/OS/Users/Can Tuksavul/linux_share`, not through the bind
   mount. ntfs-3g costs 6 to 24 times as much per file operation as `/home`
   (`../windows_partition/ARCH.md`), and the Proton wiki keeps the Wine prefix
   on a Linux file system. Game files can go on NTFS; Wine prefixes stay on
   `/home`.
3. Sandbox: Heroic cannot use a Wine installed on the host. This host has none,
   and Heroic downloads its own Wine and Proton builds.

## HD Mod for the Complete edition

1. Heroic builds the launch options of a GOG game from the `playTasks` in
   `goggame-<id>.info`. The Horn of the Abyss package (id 1718139055) ships
   HD Mod 5.8 R25 and declares the task "HD-Mod Settings" (`HD_Launcher.exe`).
   The Complete package (id 1207658787) ships no HD Mod file and declares only
   `Heroes3.exe`. Heroic therefore offers no HD option for Complete.
2. HD Mod installs into the game directory. The loader of Windows and Wine
   loads only the DLLs named in an executable's import table, and
   `Heroes3.exe` names no HD Mod DLL. "Create HD exe" in `HD_Launcher.exe`
   therefore writes `Heroes3_HD.exe`, a copy whose import table names
   `_hd3_.dll` (HD Mod's entry point) in the slot of `mss32.dll`, and the
   system `DDRAW.dll` in place of GOG's `xdd.dll` (`objdump -p`). The
   original stays unchanged. The GOG HotA package ships the equivalent
   `h3hota HD.exe` ready-made (`nullmss` replaced by `_hd3_.dll`), so HotA
   needs no such step.
3. Decision: install HD Mod 5.8 R31 into the Complete directory. The two GOG
   packages stay separate, and each updater changes only its own directory.
4. Heroic's per-game alternative executable (`targetExe` in
   `GamesConfig/1207658787.json`) replaces the missing launch option. The GOG
   `.info` file stays unchanged, so a GOG repair cannot revert the setting.
5. The installer runs in the prefix that Heroic assigned to the game, with the
   environment that Heroic's own launch uses (`heroic.log`, 2026-11-14 14:21:45).
6. The author's download page lists the primary link
   `heroes3hd.com/HoMM3_HD_Latest_setup.exe` and MIRROR 1
   `h3hota.com/HD/HoMM3_HD_Latest_setup.exe`. On 2026-11-14 MIRROR 1 served a
   copy of HD Mod 5.8 R31 whose loader offset table places the compressed
   engine (`setup.e32`) one byte before its true position, with a table CRC
   valid for those values; Inno Setup reports "The setup files are corrupted"
   on every system. The primary link serves the correct file.
   `install_hd_mod.sh` downloads from the primary link.
   `repair_inno_offsets.py` emulates the loader's
   checks: offset table CRC, chunk CRCs of the engine block, LZMA1
   decompression, x86 call-instruction reversal, engine CRC32. It searches up
   to 64 bytes around the recorded offset, and rewrites only the engine
   offset, the total size and the table CRC. An installer that passes at the
   recorded offset leaves the tool unchanged, so the step stays correct after
   an upstream fix.
7. GOG's `Heroes3.exe` imports DDrawCompat under the name `xdd.dll`, and
   reports describe failures of that import under Wine. `Heroes3_HD.exe`
   imports `DDRAW.dll` instead, so the HD path does not load `xdd.dll`.
