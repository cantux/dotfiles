#!/usr/bin/env bash
# Bootstrap a fresh Mac to today's package set, then sync dotfiles.
# Idempotent: safe to re-run. Restore order is: Homebrew -> formulae ->
# casks -> pipx tools -> dotfiles + vim plugins -> iTerm2 key map.
#
# Regenerate the formula list with:  brew leaves --installed-on-request
# (these are the packages installed on request, not pulled in as deps).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Homebrew ---------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
brew update

# --- Formulae (brew leaves --installed-on-request) --------------------------
brew install \
  bash-completion@2 \
  borgbackup \
  clang-format \
  cmake \
  cppcheck \
  cscope \
  llvm \
  make \
  node \
  pipx \
  poppler \
  python@3.13 \
  qemu \
  rclone \
  rust-analyzer \
  tmux \
  universal-ctags \
  vim

# --- Casks ------------------------------------------------------------------
brew install --cask iterm2

# --- pipx CLI tools ---------------------------------------------------------
pipx ensurepath
pipx install yapf
pipx install cpplint

# --- Dotfiles + vim plugins -------------------------------------------------
"$REPO/sync.sh"
# vim-plug bootstraps itself on first launch; install plugins headless.
vim -es -u "$HOME/.vimrc" -c 'PlugInstall --sync' -c 'qa!' </dev/null || true

# --- iTerm2 key map ---------------------------------------------------------
# Ctrl+Enter / Shift+Enter -> distinct escape sequences (for Claude Code).
# Safe here: iTerm2 was just installed and isn't running yet.
"$REPO/iterm2/apply-keymap.sh"

echo "Done. Open a new shell (or 'source ~/.bashrc') to pick up PATH changes."
