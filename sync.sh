#!/usr/bin/env bash
# Copy this repo's dotfiles into $HOME.
# Run after pulling, switching branches, or when first installing.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

items=(
  .bashrc
  .bash_aliases
  .tmux.conf
  .gitconfig
  .vimrc
  .vim
)

echo "Syncing dotfiles: $REPO -> $HOME"
for item in "${items[@]}"; do
  src="$REPO/$item"
  dst="$HOME/$item"
  if [[ ! -e "$src" ]]; then
    echo "  skip   $item (not in repo)"
    continue
  fi
  rm -rf "$dst"
  cp -R "$src" "$dst"
  echo "  copied $item"
done
echo "Done. Open a new shell or 'source ~/.bashrc' to pick up changes."
