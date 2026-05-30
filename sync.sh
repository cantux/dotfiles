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
  .claude/keybindings.json
)

# Runtime data that lives under synced dirs (e.g. ~/.vim) but is NOT in the
# repo. Never delete these or we'd wipe installed plugins / undo history.
excludes=(
  --exclude 'plugged'      # vim-plug installed plugins (incl. built YCM)
  --exclude 'undodir'
  --exclude 'vimundo'
  --exclude '.netrwhist'
  --exclude '.DS_Store'
)

echo "Syncing dotfiles: $REPO -> $HOME"
for item in "${items[@]}"; do
  src="$REPO/$item"
  dst="$HOME/$item"
  if [[ ! -e "$src" ]]; then
    echo "  skip   $item (not in repo)"
    continue
  fi
  if [[ -d "$src" ]]; then
    mkdir -p "$dst"
    rsync -a --delete "${excludes[@]}" "$src/" "$dst/"
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
  fi
  echo "  synced $item"
done
echo "Done. Open a new shell or 'source ~/.bashrc' to pick up changes."
