# Display diagnosis

Dell laptop, hybrid graphics (Intel UHD CometLake-H + NVIDIA RTX 2060 Max-Q),
CentOS Stream 10. Originally created because CentOS Stream 10 failed to
properly connect to a Dell 4K display over the WD19TB Thunderbolt dock's USB
connection. Two rounds of investigation so far, in this directory:

## 1. `env_setup.md` — GRUB / NVIDIA / kernel fix (resolved)

5 GRUB kernel entries, only one worked: `nouveau` was loading instead of the
proprietary `nvidia` driver on some kernels (no display), and one kernel
(`6.12.0-214`) was missing `kernel-modules`/`kernel-modules-extra` entirely
(no display, no USB ethernet — same dock, same root cause class: incomplete
per-kernel driver set).

Fixed via `grubby --update-kernel=ALL --args=rd.driver.blacklist=nouveau...`,
installing the missing kernel packages, and a `dracut` rebuild. Verified
self-perpetuating across later kernel updates (201 → 224 → 248 so far): the
blacklist survives via BLS's shared `kernelopts`, and DKMS auto-builds nvidia
for each new kernel without manual intervention. Full diagnosis, root causes,
and exact commands are in the file itself.

## 2. `display_diag.sh` / `display_diag_logs/` — dock vs. BIOS root-cause hunt (open)

Even after the above fix, two candidates remain for why the display
connection was originally unreliable specifically over the dock:

1. Use of the WD19TB Thunderbolt dock's video path (vs. a direct connection).
2. The BIOS "Direct Output Mode" setting.

**Current known-good baseline:** monitor connected directly to the laptop
(not through the dock's video output), Direct Output Mode disabled in BIOS.
The dock itself stays attached via Thunderbolt for power/USB-hub/ethernet —
only the video path was moved off it. In this state the external monitor is
driven by `i915` (the Intel iGPU) via `card1-DP-1`, not the NVIDIA card,
which is worth knowing before changing anything: it tells you which
`card*-*` connector to watch for a routing change if Direct Output Mode ever
gets toggled.

`display_diag.sh <label>` snapshots the state relevant to this investigation
(kernel, dock USB presence, GPU↔driver binding, DRM connector status per
card, `nvidia-smi`, dmesg/journalctl audio-adjacent... actually
display-adjacent lines: nvidia/nouveau/i915/drm/edid/hotplug/link-training,
and GNOME's mutter/monitor-manager journal lines) to
`display_diag_logs/<label>_<timestamp>.log`, so successive runs are diffable.

**Test plan (not yet executed — the current setup works, so no changes have
been made)**, one variable at a time:

| Step | Config | Change from previous |
|---|---|---|
| A (done) | Direct connect, DOM off | baseline, known good — `A_direct_DOMoff` log in this dir |
| B | Direct connect, DOM **on** | reboot to BIOS (F2), flip Direct Output Mode on |
| C | **Dock**, DOM on | move the monitor cable to the WD19TB's video output, no BIOS trip |
| D | Dock, DOM **off** | reboot to BIOS, flip DOM back off |

Run `./display_diag.sh <label>` after each reboot (e.g. `B_direct_DOMon`),
and fill in the manual Y/N + notes line at the bottom of the generated log
(does the screen actually come up at native 4K, any flicker/blanking). Once
all 4 exist, diff them for:

- Which card (`card0-DP-*` = nvidia, `card1-DP-*` = i915) claims the
  external connector — tells you whether Direct Output Mode changes GPU
  routing at all.
- New dmesg lines around EDID/link-training/hotplug in B/C/D that aren't in A.
- If B shows no change from A, Direct Output Mode is likely a no-op without
  the dock — pointing at the dock (or the dock+DOM interaction) rather than
  DOM alone.
