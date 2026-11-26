# MAP

Root of this work: `~/Projects/dotfiles`, branch `centos_xps_9700`. This
directory documents the Heroic Games Launcher installation; it holds no
configuration that `sync.sh` deploys.

## Components

| Path (repo-relative) | Role |
|---|---|
| `heroic/README.md` | Entry point: install and start. |
| `heroic/install_hd_mod.sh` | Downloads HD Mod, verifies it with `repair_inno_offsets.py`, and installs it into the Complete edition through Heroic's umu and Proton. |
| `heroic/repair_inno_offsets.py` | Emulates the Inno Setup loader checks; repairs a wrong engine offset in the loader offset table. |
| `heroic/ARCH.md` | Terms, the arm64 failure, channel choice, invariants, trade-offs. |
| `heroic/INSTR.md` | Install, verify, debug, remove. |
| `heroic/WORKLOG.md` | Chronological record. |
| `heroic/EVIDENCE_INSPIRATION_REFERENCE.md` | Sources and parallels. |
| `README.md`, section "Heroic Games Launcher" | Points here. |

## Live locations

| Path | Created by |
|---|---|
| `~/.local/share/flatpak/app/com.heroicgameslauncher.hgl` | `flatpak install` |
| `~/.local/share/flatpak/runtime/org.freedesktop.Platform*` | `flatpak install` (runtime and extensions) |
| `~/.local/share/flatpak/exports/share/applications/com.heroicgameslauncher.hgl.desktop` | `flatpak install` (the icon) |
| `~/.var/app/com.heroicgameslauncher.hgl` | first start (configuration and cache) |
| `~/Games/Heroic` | first start (default game directory) |
| `~/Games/Heroic/HoMM 3 Complete` | Heroic GOG install; `install_hd_mod.sh` adds HD Mod; HD_Launcher adds `Heroes3_HD.exe` |
| `~/Games/Heroic/Prefixes/Heroes of Might and Magic 3 Complete` | `install_hd_mod.sh` or the first Heroic launch (Wine prefix) |
| `~/Downloads/hd_mod/HoMM3_HD_Latest_setup.exe` | `install_hd_mod.sh` (HD Mod installer as downloaded; on 2026-11-14 the defective MIRROR 1 copy) |
| `~/Downloads/hd_mod_primary/HoMM3_HD_Latest_setup.exe` | manual download of the primary link, 2026-11-14 (reference copy for the comparison) |
| `~/Downloads/hd_mod/HoMM3_HD_Latest_setup_verified.exe` | `repair_inno_offsets.py` (verified or repaired copy that the script installs) |
