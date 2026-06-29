#!/usr/bin/env bash
# Build a recent tmux (>= 3.4) from source into /usr/local, because CentOS
# Stream 10 only packages tmux 3.3a -- which predates `extended-keys-format
# csi-u` and so relays Shift+Enter / Ctrl+Enter in the old xterm form that
# Claude Code doesn't read as a modifier (the keys collapse to plain Enter).
#
# After this completes, /usr/local/bin/tmux shadows /usr/bin/tmux on PATH, the
# guarded line in .tmux.conf activates, and modified keys carry through tmux --
# matching the mac branch. Idempotent: safe to re-run.
set -euo pipefail

# Latest stable tag (any tmux >= 3.4 has the feature). Override with
# TMUX_VERSION=3.6 ./install_tmux.sh ; falls back if the GitHub API is unreachable.
TMUX_VERSION="${TMUX_VERSION:-$(curl -fsSL https://api.github.com/repos/tmux/tmux/releases/latest \
  | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)}"
TMUX_VERSION="${TMUX_VERSION:-3.5a}"

# --- Build deps -------------------------------------------------------------
# libevent-devel lives in CRB, so make sure EPEL + CRB are on (init.sh also does
# this; harmless to repeat).
sudo dnf install -y dnf-plugins-core epel-release
sudo dnf config-manager --set-enabled crb
sudo dnf install -y gcc make automake autoconf pkgconf-pkg-config bison \
  libevent-devel ncurses-devel

# --- Fetch + build ----------------------------------------------------------
src="$(mktemp -d)"
trap 'rm -rf "$src"' EXIT
cd "$src"
curl -fLO "https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz"
tar xzf "tmux-${TMUX_VERSION}.tar.gz"
cd "tmux-${TMUX_VERSION}"
./configure --prefix=/usr/local
make -j"$(nproc)"
sudo make install

hash -r
echo
echo "Installed: $(/usr/local/bin/tmux -V)   (system: $(/usr/bin/tmux -V 2>/dev/null || echo none))"
echo "Now: 'tmux kill-server' and start a fresh tmux so .tmux.conf re-applies."
echo "Verify: tmux show -s extended-keys-format   (should print 'csi-u', not error)"
