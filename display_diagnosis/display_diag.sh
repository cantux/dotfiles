#!/usr/bin/env bash
# Snapshot the state relevant to the WD19TB-dock / Direct-Output-Mode display
# investigation (see env_setup.md). Run identically after each reboot into a
# test configuration so the results are diffable across configs.
#
# Usage: ./display_diag.sh <label>
#   label examples: A_direct_DOMoff  B_direct_DOMon  C_dock_DOMon  D_dock_DOMoff
set -euo pipefail

LABEL="${1:?usage: display_diag.sh <label>, e.g. A_direct_DOMoff}"
OUTDIR="$HOME/display_diag_logs"
mkdir -p "$OUTDIR"
OUT="$OUTDIR/${LABEL}_$(date +%Y%m%d_%H%M%S).log"

{
  echo "## $LABEL  ($(date))"
  echo

  echo "--- kernel / boot ---"
  uname -r
  uptime -s
  echo

  echo "--- dock present on USB? ---"
  lsusb | grep -iE "dell|thunderbolt" || echo "(no dock-related USB devices seen)"
  echo

  echo "--- GPU -> driver binding ---"
  lspci -k | grep -A3 -iE "vga|3d controller|display controller"
  echo

  echo "--- DRM connector status (which card/output has the external monitor) ---"
  for c in /sys/class/drm/card*-*/status; do
    conn=$(basename "$(dirname "$c")")
    card=$(echo "$conn" | cut -d- -f1)
    driver=$(cat "/sys/class/drm/$card/device/uevent" 2>/dev/null | grep -oP '(?<=DRIVER=).*')
    printf "%-16s driver=%-8s status=%s\n" "$conn" "$driver" "$(cat "$c" 2>/dev/null)"
  done
  echo

  echo "--- nvidia-smi ---"
  nvidia-smi 2>&1 | head -15
  echo

  echo "--- dmesg: nvidia/nouveau/i915/drm/edid/hotplug/link-training since boot ---"
  dmesg -T 2>/dev/null | grep -iE "nvidia|nouveau|i915|drm|edid|hotplug|link.train|thunderbolt" || \
    sudo dmesg -T 2>&1 | grep -iE "nvidia|nouveau|i915|drm|edid|hotplug|link.train|thunderbolt"
  echo

  echo "--- journalctl (this boot): mutter/gnome-shell/monitor-manager ---"
  journalctl -b 0 --no-pager 2>&1 | grep -iE "mutter|gnome-shell|monitor.manager|display.manager" | tail -60
  echo

  echo "--- MANUAL CHECK (fill in by hand) ---"
  echo "External 4K display lit up correctly (native res/refresh, no flicker)? [Y/N]:"
  echo "Notes:"
} > "$OUT" 2>&1

echo "Saved: $OUT"
