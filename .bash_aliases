alias cdp="cd ~/Projects"
alias c="clear"
alias cd..="cd .."

# Copy this repo's dotfiles into $HOME.
alias dotsync='~/Projects/dotfiles/sync.sh'

# tmux
alias tl="tmux list-sessions"            # list sessions
alias ta="tmux attach -t"                # attach: ta <name>
alias tn="tmux new -s"                   # new named session: tn <name>
alias tk="tmux kill-session -t"          # kill: tk <name>
alias tka="tmux kill-server"             # kill all sessions
# Attach to last session, or start one if none exist.
tt() { tmux attach || tmux new -s main; }

# Run Claude with max effort on the latest Opus model.
alias cmax="claude --model opus --effort max"

# Open Claude in a new git worktree with an iTerm2/tmux session.
# Usage: ccw <worktree-name> [extra claude flags]
ccw() { claude --tmux=classic --worktree "$@"; }
