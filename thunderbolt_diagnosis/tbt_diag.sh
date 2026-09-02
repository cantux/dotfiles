#!/usr/bin/env bash
set -euo pipefail

LABEL="${1:?usage: tbt_diag.sh <label>, e.g. dock_left_front}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTDIR="$HERE/tbt_diag_logs"
mkdir -p "$OUTDIR"
OUT="$OUTDIR/${LABEL}_$(date +%Y%m%d_%H%M%S).log"

{
  echo "## $LABEL  ($(date))"
  echo

  echo "--- kernel / firmware ---"
  uname -r
  cat /sys/class/dmi/id/product_name /sys/class/dmi/id/bios_version
  echo

  echo "--- thunderbolt routers (ground truth: is it actually on TB?) ---"
  for d in /sys/bus/thunderbolt/devices/*/; do
    [ -e "$d/device_name" ] || continue
    printf "%-10s %-32s nvm=%-8s auth=%s\n" \
      "$(basename "$d")" "$(cat "$d/device_name")" \
      "$(cat "$d/nvm_version" 2>/dev/null)" "$(cat "$d/authorized" 2>/dev/null)"
    [ -e "$d/rx_speed" ] && echo "           link: $(cat "$d/rx_speed") x $(cat "$d/rx_lanes") lanes rx / $(cat "$d/tx_speed") x $(cat "$d/tx_lanes") lanes tx"
    echo "           path: $(readlink -f "$d" | sed 's|/sys/devices||')"
  done
  echo "domain security: $(cat /sys/bus/thunderbolt/devices/domain*/security 2>/dev/null | tr '\n' ' ')"
  echo

  echo "--- boltctl ---"
  boltctl list 2>&1
  echo

  echo "--- PCIe tunnel check (dock TB controller + its xHCI must be present) ---"
  lspci -nn | grep -iE 'thunderbolt|JHL' || echo "(none)"
  echo

  echo "--- typec ports / alt modes (NOTE: Thunderbolt3 active=no here is a known false negative) ---"
  for p in /sys/class/typec/port[0-9]; do
    n=$(basename "$p")
    echo "$n: partner=$([ -d "$p-partner" ] && echo YES || echo no) pwr=$(cat "$p/power_operation_mode" 2>/dev/null)"
    for am in "$p-partner"/*.*; do
      [ -d "$am" ] || continue
      echo "    $(basename "$am") svid=$(cat "$am/svid" 2>/dev/null) active=$(cat "$am/active" 2>/dev/null) desc=$(cat "$am/description" 2>/dev/null)"
    done
  done
  echo

  echo "--- USB tree ---"
  lsusb -t
  echo
  lsusb
  echo

  echo "--- DRM connectors ---"
  for c in /sys/class/drm/card*-*/status; do
    conn=$(basename "$(dirname "$c")")
    card=$(echo "$conn" | cut -d- -f1)
    drv=$(grep -oP '(?<=DRIVER=).*' "/sys/class/drm/$card/device/uevent" 2>/dev/null)
    st=$(cat "$c" 2>/dev/null)
    [ "$st" = connected ] && extra=" mode=$(head -1 "$(dirname "$c")/modes" 2>/dev/null) ddc=$([ -e "$(dirname "$c")/ddc" ] && echo native || echo MST)"|| extra=""
    printf "%-16s driver=%-8s status=%s%s\n" "$conn" "$drv" "$st" "$extra"
  done
  echo

  echo "--- dock net / audio ---"
  ip -br link | grep -vE '^(lo|lxc|cilium)' || true
  cat /proc/asound/cards
  echo

  echo "--- fwupd view (dell_dock plugin is expected to FAIL on the base EC) ---"
  fwupdmgr get-devices 2>/dev/null | grep -A3 -iE 'thunderbolt|dock' | head -40
  journalctl -b --no-pager -u fwupd 2>/dev/null | grep -iE 'dell_dock|dock type|thunderbolt' | tail -10
  echo

  echo "--- journal: thunderbolt / xhci / typec / drm ---"
  journalctl -k -b --no-pager 2>/dev/null | grep -iE 'thunderbolt|typec|xhci|r8152|drm' | tail -60
  echo

  echo "--- MANUAL CHECK (fill in by hand) ---"
  echo "Physical port used (NW/NE/SW/SE):"
  echo "Dock enumerated as a TB router (see section above)? [Y/N]:"
  echo "Displays / ethernet / audio all up? [Y/N]:"
  echo "Notes:"
} > "$OUT" 2>&1

echo "Saved: $OUT"
