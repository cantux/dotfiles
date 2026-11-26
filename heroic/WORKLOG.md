# WORKLOG

## 2026-11-14 — Heroic Games Launcher: arm64 AppImage replaced by the Flatpak

1. Report: the integrated Heroic AppImage did not start from its icon.
2. Diagnosis: `uname -m` printed `x86_64`; `file` printed `ARM aarch64` for
   `~/Applications/Heroic-2.22.4-linux-arm64_565819764a1bc049c50d535a9dddaf95.AppImage`.
   Its SHA-256 equalled the digest of the release asset
   `Heroic-2.22.4-linux-arm64.AppImage` (`gh api .../releases/tags/v2.22.4`).
   Running it printed `failed to execute patched runtime: Exec format error`.
   The user journal of 2026-11-14 held no line for the failed clicks.
3. Channel analysis: `dnf repoquery --arch i686` returned 0 packages; the
   Flathub metadata of the application declares `Compat.i386` and `GL32`;
   Flathub published `GL.nvidia-620-70-06` and `GL32.nvidia-620-70-06`,
   matching the loaded kernel module 620.70.06. Decision: Flatpak (ARCH.md).
4. Install: `flatpak install --user -y flathub com.heroicgameslauncher.hgl`
   exited 0 and installed v2.22.4 (commit `8f930918…3267`), runtime 26.08,
   `Compat.i386`, `GL32.default`, and both NVIDIA extensions. Free space on
   `/home` went from 18 GiB to 14 GiB.
5. Verification: a 40-second run reached `[Backend]: Frontend Ready` within
   one second, reported the Flatpak container, both GPUs (`nvidia`, `i915`),
   and Legendary 0.21.1, gogdl 1.3.0, Nile 1.2.0. The error lines came from a
   first start (missing `GamesConfig`, no GOG login) and from the `timeout`
   stop (D-Bus disconnect).
6. Not done: the auto-mode permission classifier refused the deletion of the
   arm64 AppImage. The file and its AppImageLauncher entry remain in
   `~/Applications` and `~/.local/share/applications` for the user to delete.
7. The i686 argument holds for every CentOS Stream 10 machine; the NVIDIA
   version is specific to this one. Not committed; the user decides on the
   commit and its branch.

## 2026-11-14 — HD Mod for Heroes of Might and Magic 3 Complete

1. Request: play the original campaigns of the Complete edition, not HotA,
   with HD Mod; Heroic showed an HD option for HotA only.
2. Findings: two GOG installs in `~/Games/Heroic`. The HotA package declares
   an HD-Mod task in `goggame-1718139055.info`; the Complete package declares
   `Heroes3.exe` only and holds no HD Mod file. HotA ran from 14:21:45 to
   14:23:16; Complete had never started, and its prefix did not exist.
3. Download: `https://h3hota.com/HD/HoMM3_HD_Latest_setup.exe`, the URL of
   Lutris installer 12522; HTTP 200, 19,434,502 bytes, SHA-256
   `801c6685e04146d782a30fc21b81adf614894d7c0e5c7efc77ba7297f2ac522a`,
   Inno Setup 5.5.7, version resource "HoMM3 HD+ 5.8 R31".
4. Refused: the auto-mode permission classifier refused the unattended run of
   the installer ("Undermining Oversight"). The procedure became
   `install_hd_mod.sh` for the user to run; `bash -n` passed; not executed.
5. Pending for the user: run the script, set the alternative EXE, press
   "Create HD exe" in HD_Launcher (INSTR.md).

## 2026-11-14 — HD Mod R31 installer: "The setup files are corrupted"

1. Report: the user ran `install_hd_mod.sh`; Inno Setup showed "The setup
   files are corrupted. Please obtain a new copy of the program." The run
   created the prefix; it wrote no installer log and no HD Mod file.
2. Download ruled out: local size 19,434,502 bytes equals `Content-Length`
   and the ETag `6af61946-1288c06` (`Last-Modified` 2026-11-12 19:53:42 GMT).
3. Loader offset table (at byte 341,372; table CRC valid): `TotalSize`
   19,434,501, `OffsetEXE` 18,914,422, `UncompressedSizeEXE` 1,410,560,
   `CRCEXE` 2,236,700,367, `Offset0` 18,884,437, `Offset1` 344,576.
4. Setup data #0 at `Offset0`: ID `Inno Setup Setup Data (5.5.7) (u)`; both
   blocks pass every chunk CRC; the second block ends at 18,914,423, one byte
   past `OffsetEXE`.
5. Engine block: at `OffsetEXE` the header CRC fails, which is the loader's
   corruption error. At `OffsetEXE + 1` every chunk CRC passes, the LZMA1
   stream decompresses to 1,410,560 bytes starting with `MZ`, and after the
   call-instruction reversal its CRC32 equals `CRCEXE`; the block ends at the
   last byte of the file. Conclusion at that time: setup data #0 grew by one
   byte after the compiler wrote the table. Superseded by the next entry.
6. Repair: `repair_inno_offsets.py` sets `OffsetEXE` and `TotalSize` to the
   verified engine block and recomputes the table CRC. `cmp -l` lists 6
   changed bytes, all in the table. The repaired copy passes the tool's
   checks unchanged. SHA-256: original `801c6685…522a`, repaired
   `2baca940…99f4`.
7. `install_hd_mod.sh` now passes every download through the tool and installs
   the verified copy; yapf reports no change, `bash -n` passes.
8. Pending for the user: run `install_hd_mod.sh` again.

## 2026-11-14 — HD Mod installed; defect located on MIRROR 1; HD exe explained

1. Outcome: the user ran the script; `hd_mod_install.log` records
   `Installation process succeeded.` at 14:59:21 (engine Inno Setup 5.6.1).
   HD_Launcher wrote `Heroes3_HD.exe` at 15:03:27; Heroic's `targetExe` is
   `HD_Launcher.exe`; the launch session ran from 15:02:46.
2. Report channel: the author page
   (`sites.google.com/site/heroes3hd/eng/author`) lists e-mail and forum
   threads; its download page lists the primary link `heroes3hd.com` and
   MIRROR 1 `h3hota.com`, the URL that Lutris installer 12522 and this
   script had used.
3. Primary link: 19,434,502 bytes, version "HoMM3 HD+ 5.8 R31", SHA-256
   `2baca94058b22b1330d1db3a92e9eb9ebb138b20ed4eceb59e60b318904699f4`,
   identical to the repaired copy; `repair_inno_offsets.py` reports
   `consistent`. MIRROR 1 still served ETag `6af61946-1288c06`.
4. Correction: the two files differ only in the six table bytes. MIRROR 1
   holds a table rewritten with `TotalSize` and `OffsetEXE` one byte too small
   and a CRC valid for them; setup data #0 did not grow. The defect belongs
   to the MIRROR 1 copy, not to the release.
5. Change: `install_hd_mod.sh` downloads from the primary link; the
   verification step stays.
6. HD exe: `objdump -p` shows that `Heroes3_HD.exe` imports `_hd3_.dll` in the
   slot of `mss32.dll` and `DDRAW.dll` in place of `xdd.dll`; `h3hota HD.exe`
   differs from `h3hota.exe` in the same slot (`nullmss` to `_hd3_.dll`).
   ARCH.md, HD Mod item 2, records the mechanism.
