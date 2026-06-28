# Environment defaults

- OS: CentOS Stream 10 (`el10`, x86_64), package manager `dnf` with EPEL + CRB enabled
- Shell: system bash (`/bin/bash`)
- Access: headless server over SSH (no local GUI)
- Multiplexer: tmux (sessions); clipboard yank uses OSC52 so copy works over SSH
- This repo: tracked dotfiles copied into `$HOME` by `sync.sh` (`.bashrc`, `.vimrc`, `.vim`, the `.claude/` and `.config/` files, etc. — see README "What's tracked" for the full list)
- Working branch: `centos` (CentOS port of the `mac` branch)

# Workflow

- After editing any tracked dotfile in this repo, run `./sync.sh` to copy it into `$HOME`. Edits here do not take effect until synced — `sync.sh` does `cp`/`rsync`, not symlinks.
- For live-reloading after sync: `source ~/.bashrc` for shell changes, `tmux source-file ~/.tmux.conf` for tmux, `:source $MYVIMRC` inside vim.
