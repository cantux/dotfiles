#!/usr/bin/env bash
set -euo pipefail

UNIT=home-ctuk-windows_partition.mount
WINDOWS_VOLUME=/run/media/ctuk/OS
SHARE_DIR="$WINDOWS_VOLUME/Users/Can Tuksavul/linux_share"
MOUNT_POINT=/home/ctuk/windows_partition
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "${1:-}" = "--undo" ]; then
  sudo systemctl disable --now "$UNIT"
  sudo rm -f "/etc/systemd/system/$UNIT"
  sudo systemctl daemon-reload
  if [ -d "$MOUNT_POINT" ]; then
    sudo rmdir "$MOUNT_POINT"
  fi
  echo "Undone. $SHARE_DIR and its files are kept."
  exit 0
fi

sudo install -m 0644 "$SCRIPT_DIR/$UNIT" "/etc/systemd/system/$UNIT"
sudo systemctl daemon-reload
sudo systemctl enable "$UNIT"

if mountpoint -q "$WINDOWS_VOLUME"; then
  mkdir -p "$SHARE_DIR"
  sudo systemctl start "$UNIT"
  findmnt "$MOUNT_POINT"
else
  echo "$WINDOWS_VOLUME is not mounted. The bind mount starts when the Windows volume is unlocked and mounted in Files."
fi
