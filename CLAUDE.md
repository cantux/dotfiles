# Environment defaults

- OS: macOS (Apple Silicon, Homebrew at `/opt/homebrew`)
- Shell: Homebrew bash (`/opt/homebrew/bin/bash`), set as the login shell
- Terminal: iTerm2
- Multiplexer: tmux (sessions)
- This repo: tracked dotfiles copied into `$HOME` by `sync.sh` (`.bashrc`, `.bash_aliases`, `.tmux.conf`, `.gitconfig`, `.vimrc`, `.vim`)
- Working branch: `mac` (macOS port of the original Linux dotfiles)

# Workflow

- After editing any tracked dotfile in this repo, run `./sync.sh` to copy it into `$HOME`. Edits here do not take effect until synced — `sync.sh` does `cp -R`, not symlinks.
- For live-reloading after sync: `source ~/.bashrc` for shell changes, `tmux source-file ~/.tmux.conf` for tmux, `:source $MYVIMRC` inside vim.
