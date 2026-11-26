# INSTR

## Install

1. `flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo`
2. `flatpak install --user -y flathub com.heroicgameslauncher.hgl`

## Verify

1. `flatpak info --user com.heroicgameslauncher.hgl` prints `Version: v2.22.4`
   or later.
2. `flatpak list --user --runtime | grep -E 'nvidia|Compat.i386'` prints
   `GL.nvidia-<v>`, `GL32.nvidia-<v>` and `Compat.i386`, where `<v>` is the
   version in `/proc/driver/nvidia/version` with dots replaced by hyphens.
3. `timeout 40 flatpak run com.heroicgameslauncher.hgl` opens the window and
   prints `[Backend]: Frontend Ready` and `We are running inside a Flatpak
   container`. The `FATAL ... D-Bus connection was disconnected` line at the
   end comes from `timeout` and does not indicate a fault.

## Debug

1. Start from a terminal with `flatpak run com.heroicgameslauncher.hgl`; the
   log goes to the terminal.
2. `file <path>.AppImage` must report `x86-64` for any AppImage on this
   machine; `ARM aarch64` fails with `Exec format error`.
3. After an NVIDIA driver upgrade, run `flatpak update --user` and repeat
   Verify step 2.
4. To grant a further path:
   `flatpak override --user --filesystem=<path> com.heroicgameslauncher.hgl`.

## HD Mod for the Complete edition

1. Run `~/Projects/dotfiles/heroic/install_hd_mod.sh`. The script downloads
   `HoMM3_HD_Latest_setup.exe` from `heroes3hd.com`, the primary link of the
   author's download page, to `~/Downloads/hd_mod`, prints its SHA-256,
   and checks it with `repair_inno_offsets.py`. The tool prints `consistent`
   or `repaired: ...` and writes `HoMM3_HD_Latest_setup_verified.exe`. The
   script installs that copy unattended into `~/Games/Heroic/HoMM 3 Complete`
   through Heroic's umu and Proton-CachyOS, and prints
   `Installation process succeeded.` and the `HD_Launcher.exe` entry.
   A newer upload replaces the old one only after
   `rm ~/Downloads/hd_mod/HoMM3_HD_Latest_setup.exe`.
2. In Heroic, open the settings of Heroes of Might and Magic 3 Complete and set
   "Select an alternative EXE to run" to
   `~/Games/Heroic/HoMM 3 Complete/HD_Launcher.exe`.
3. Press Play. In HD_Launcher, select `Heroes3.exe`, press "Create HD exe",
   select a resolution, and press "Play".
4. The original campaigns are under New Game, Campaign.
5. Optional: set the alternative EXE to `Heroes3_HD.exe` to start without the
   launcher.
6. Debug: the launch log is
   `~/.var/app/com.heroicgameslauncher.hgl/.local/state/Heroic/logs/games/1207658787_gog/launch.log`;
   the installer log is
   `~/Games/Heroic/Prefixes/Heroes of Might and Magic 3 Complete/drive_c/hd_mod_install.log`.
   The message "Game version undefined. You should re-create HD.exe" means
   step 3 must run again.

## Remove

1. `flatpak uninstall --user com.heroicgameslauncher.hgl`; add
   `--delete-data` to remove `~/.var/app/com.heroicgameslauncher.hgl`.
2. `flatpak uninstall --user --unused` removes runtimes that no application
   uses.
3. `~/Games/Heroic` holds the games and stays until removed by hand.
