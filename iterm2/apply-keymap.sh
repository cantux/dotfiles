#!/usr/bin/env bash
# Merge our key-map divergence (keymap-divergence.plist) into iTerm2's live
# prefs, leaving iTerm2's own default bindings alone. Idempotent.
#
# We persist ONLY the divergence, not the whole plist. iTerm2 has no full
# "default prefs" file to diff against (most defaults live in its code), so a
# clean whole-plist diff isn't possible. But the key map does ship a reference
# default, and our only change there is the two Ctrl/Shift+Enter entries.
#
# iTerm2 reads prefs at launch and rewrites them on quit, so an edit made while
# it runs is lost on quit. This script therefore skips if iTerm2 is running --
# quit it (run from Terminal.app) and re-run.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAG="$DIR/keymap-divergence.plist"
PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
PB=/usr/libexec/PlistBuddy

if pgrep -x iTerm2 >/dev/null 2>&1; then
  echo "SKIPPED: iTerm2 is running -- it would overwrite prefs on quit."
  echo "         Quit iTerm2 (run this from Terminal.app) and re-run."
  exit 0
fi

# Ensure GlobalKeyMap exists, then replace just our two keys from the fragment.
# Delete-then-merge keeps it idempotent and never duplicates entries.
"$PB" -c "Add :GlobalKeyMap dict" "$PLIST" 2>/dev/null || true
"$PB" -c "Delete :GlobalKeyMap:0xd-0x40000-0x24" "$PLIST" 2>/dev/null || true
"$PB" -c "Delete :GlobalKeyMap:0xd-0x20000-0x24" "$PLIST" 2>/dev/null || true
"$PB" -c "Merge $FRAG :GlobalKeyMap" "$PLIST"

# Flush the prefs cache so the file edit is what iTerm2 reads next launch.
killall cfprefsd >/dev/null 2>&1 || true

echo "Applied iTerm2 Ctrl/Shift+Enter key map. Relaunch iTerm2 to pick it up."
