alias cdp="cd ~/Projects"
alias c="clear"
alias cd..="cd .."

# Copy this repo's dotfiles into $HOME.
alias dotsync='~/Projects/dotfiles/sync.sh'

# Open Claude in a new git worktree with an iTerm2/tmux session.
# Usage: ccw <worktree-name> [extra claude flags]
ccw() { claude --tmux=classic --worktree "$@"; }
