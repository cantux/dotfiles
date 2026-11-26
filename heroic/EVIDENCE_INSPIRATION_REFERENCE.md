# EVIDENCE, INSPIRATION, REFERENCE

## Measurements on this machine (2026-11-14)

1. `uname -m`, `file`, `sha256sum`: architecture of host and AppImage.
2. `gh api repos/Heroic-Games-Launcher/HeroicGamesLauncher/releases/tags/v2.22.4`:
   names, sizes and SHA-256 digests of the release assets.
3. `dnf repoquery --arch i686`: 0 packages in the enabled repositories.
4. `flatpak remote-info --show-metadata flathub com.heroicgameslauncher.hgl`:
   extension points `Compat.i386`, `GL32`, `VAAPI.Intel.i386`; filesystem
   grants.
5. `/proc/driver/nvidia/version`: NVIDIA open kernel module 620.70.06.
6. `timeout 40 flatpak run com.heroicgameslauncher.hgl`: startup log.

## Sources

1. execve(2), error `ENOEXEC`: "An executable is not in a recognized format,
   is for the wrong architecture, or has some other format error".
   https://man7.org/linux/man-pages/man2/execve.2.html
2. Heroic v2.22.4 release.
   https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/tag/v2.22.4
3. Heroic downloads page: names Flatpak the best experience on any Linux
   distribution. https://heroicgameslauncher.com/downloads
4. Heroic wiki, Linux Quick Start Guide: installs the Flatpak.
   https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/wiki/Linux-Quick-Start-Guide
5. Red Hat, "How are 32-bit applications and multilib libraries supported in
   RHEL?": multilib deprecated in RHEL 9.5, removed in RHEL 10.
   https://access.redhat.com/solutions/509373
6. Red Hat Jira RHELDOCS-19269: documentation of the i686 removal in RHEL 10.
   https://issues.redhat.com/browse/RHELDOCS-19269
7. Debian wiki, Steam: 64-bit systems need 32-bit Mesa libraries for 32-bit
   titles. https://wiki.debian.org/Steam
8. steam-runtime-tools, pressure-vessel: the container imports the graphics
   stack of its host (here the Flatpak runtime).
   https://gitlab.steamos.cloud/steamrt/steam-runtime-tools/-/tree/master/pressure-vessel
9. Flathub NVIDIA GL extension: one extension per driver version.
   https://github.com/flathub/org.freedesktop.Platform.GL.nvidia
10. Proton wiki, "Using a NTFS disk with Linux and Windows": keeps
    `compatdata` (the Wine prefixes) on a Linux file system.
    https://github.com/ValveSoftware/Proton/wiki/Using-a-NTFS-disk-with-Linux-and-Windows
11. AppImageLauncher: integration into `~/Applications` and binfmt handling.
    https://github.com/TheAssassin/AppImageLauncher

12. Lutris installer 12522, "GOG + HD mod": runs
    `HoMM3_HD_Latest_setup.exe /DIR=...` into the GOG directory and starts
    `HD_Launcher.exe`; note: press "Create HD exe" to unlock "Play".
    https://lutris.net/games/install/12522/view
13. Lutris installer 12691, "GOG + HotA + HD mod": note: to run the Complete
    Edition campaigns, select "Heroes3.exe" and press "Create HD exe".
    https://lutris.net/games/install/12691/view
14. Inno Setup command-line parameters `/VERYSILENT`, `/SUPPRESSMSGBOXES`,
    `/NORESTART`, `/SP-`, `/DIR=`, `/LOG=`.
    https://jrsoftware.org/ishelp/index.php?topic=setupcmdline
15. HD Mod on Nexus Mods: requires Shadow of Death or Complete.
    https://www.nexusmods.com/heroesofmightandmagiciii/mods/3
16. gogo issue 306: GOG's `Heroes3.exe` imports DDrawCompat as `xdd.dll`.
    https://github.com/noosxe/gogo/issues/306
17. `~/.var/app/com.heroicgameslauncher.hgl/.local/state/Heroic/logs/heroic.log`,
    line of 14:21:45: the environment and `gogdl launch` command that Heroic
    used for HotA; `install_hd_mod.sh` reproduces that environment.

18. Inno Setup source (jrsoftware/issrc, 5.5 series): the loader offset table
    `TSetupLdrOffsetTable`, the compressed block format (header CRC, stored
    size, compressed flag, 4,096-byte chunks each preceded by CRC32), and
    `TransformCallInstructions`. https://github.com/jrsoftware/issrc
19. innoextract: an independent implementation of the same formats.
    https://constexpr.org/innoextract/
20. Measurement, 2026-11-14: `repair_inno_offsets.py` on the R31 download;
    the engine block passes all checks one byte after the recorded offset
    (WORKLOG.md).
21. HD Mod author page: e-mail and discussion threads.
    https://sites.google.com/site/heroes3hd/eng/author
22. HD Mod download page: primary link `heroes3hd.com`, MIRROR 1
    `h3hota.com`, MIRROR 2 on Google Drive.
    https://sites.google.com/site/heroes3hd/eng/download
23. Measurement, 2026-11-14: the primary link's SHA-256 equals the repaired
    MIRROR 1 copy; `objdump -p` import tables of `Heroes3.exe`,
    `Heroes3_HD.exe`, `h3hota.exe`, `h3hota HD.exe`.

## Parallels

1. OCI image index: a registry holds one manifest per architecture and the
   client selects the host's; a container started from an image of the wrong
   architecture fails with the same `exec format error`. A download page with
   one file per architecture leaves that selection to the reader.
   https://github.com/opencontainers/image-spec/blob/main/image-index.md
2. NVIDIA Container Toolkit: injects the host's userspace driver libraries,
   matched to the loaded kernel module, into a container. Flatpak solves the
   same matching problem with one runtime extension per driver version.
   https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/
