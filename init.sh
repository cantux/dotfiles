#!/usr/bin/env bash
# Bootstrap a fresh CentOS Stream 10 box to today's package set, then sync
# dotfiles. Idempotent: safe to re-run. Order is: repos (EPEL + CRB) ->
# dnf packages -> rustup (rust-analyzer) -> pipx tools -> dotfiles + vim plugins.
#
# CentOS port of the macOS init.sh. The mac package set came from
# `brew leaves --installed-on-request`; the dnf equivalents are below
# (plus rustup for rust-analyzer, which dnf/EPEL doesn't package).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Repos: EPEL + CRB ------------------------------------------------------
# borgbackup, cppcheck, rclone, ctags (universal-ctags), gtest-devel and pipx
# live in EPEL; EPEL packages may pull build deps from CRB (CodeReady Builder),
# so enable both. epel-release ships in CentOS Stream's extras-common repo.
sudo dnf install -y dnf-plugins-core epel-release
sudo dnf config-manager --set-enabled crb
sudo dnf makecache

# --- Toolchain + packages ---------------------------------------------------
# "Development Tools" pulls in gcc, gcc-c++, make, autoconf, git, etc.
sudo dnf groupinstall -y "Development Tools"

# Single transaction across base/AppStream/CRB + EPEL. Trailing comment on each
# line maps it back to the Homebrew formula it replaces.
sudo dnf install -y \
  bash-completion \
  borgbackup \
  clang \
  clang-analyzer \
  clang-tools-extra \
  cmake \
  cppcheck \
  cscope \
  ctags \
  curl \
  gtest-devel \
  kitty \
  llvm \
  make \
  nodejs \
  nodejs-npm \
  poppler-utils \
  python3 \
  python3-devel \
  python3-pip \
  pipx \
  qemu-img \
  qemu-kvm \
  rclone \
  rsync \
  tmux \
  valgrind \
  vim-enhanced
# Mapping notes (mac formula -> CentOS):
#   bash-completion@2  -> bash-completion
#   clang-format,llvm  -> clang clang-tools-extra llvm (clang-format/clang-tidy/clangd)
#   scan-build         -> clang-analyzer
#   node               -> nodejs nodejs-npm
#   poppler            -> poppler-utils
#   python@3.13        -> python3 python3-devel (el10 default python3 is 3.12)
#   qemu               -> qemu-kvm qemu-img
#   universal-ctags    -> ctags (EPEL ships Universal Ctags 6.x as `ctags`)
#   (Apple `leaks`)    -> valgrind
#   googletest         -> gtest-devel (for the ~/.vim/templates/gtest.cpp build)
#   (iTerm2 on mac)    -> kitty (EPEL; needed for a distinct Ctrl+Enter via the
#                         ESC[13;5u map in .config/kitty/kitty.conf)

# --- Hardware-specific packages (this machine; not part of the mac port) ---
# Without this, the Intel SOF audio DSP (CometLake + rt711/rt715/rt1308
# soundwire codecs) has no firmware to load, so it never registers an ALSA
# card and PipeWire only ever shows "Dummy Output". If this is installed
# after the DSP already failed to probe (i.e. not during a fresh init.sh
# run), it won't take effect until the PCI device is rebound or the box is
# rebooted:
#   echo 0000:00:1f.3 | sudo tee /sys/bus/pci/drivers/sof-audio-pci-intel-cnl/unbind
#   echo 0000:00:1f.3 | sudo tee /sys/bus/pci/drivers/sof-audio-pci-intel-cnl/bind
sudo dnf install -y alsa-sof-firmware

# --- rust-analyzer (not packaged in dnf/EPEL; install via rustup) -----------
if [ ! -x "$HOME/.cargo/bin/rust-analyzer" ]; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  # shellcheck disable=SC1091
  source "$HOME/.cargo/env"
  rustup component add rust-analyzer
fi

# --- pipx CLI tools ---------------------------------------------------------
pipx ensurepath
pipx install yapf
pipx install cpplint

# --- Dotfiles + vim / tmux plugins -----------------------------------------
"$REPO/sync.sh"
# vim-plug bootstraps itself on first launch; install plugins headless.
vim -es -u "$HOME/.vimrc" -c 'PlugInstall --sync' -c 'qa!' </dev/null || true

# TPM & tmux plugins
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
tmux start-server \; source-file "$HOME/.tmux.conf" 2>/dev/null || true
"$HOME/.tmux/plugins/tpm/bin/install_plugins" || true

echo "Done. Open a new shell (or 'source ~/.bashrc') to pick up PATH changes."

