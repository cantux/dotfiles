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

# C++ static analysis: Homebrew llvm is keg-only, so expose its tools without
# shadowing system clang on PATH.
alias clang-tidy="/opt/homebrew/opt/llvm/bin/clang-tidy"
alias scan-build="/opt/homebrew/opt/llvm/bin/scan-build"

# C++ sanitizer build+run helpers. macOS supports ASan/UBSan/TSan; MSan does not.
# usage: asan foo.cpp   (builds with ASan+UBSan, then runs ./a.out)
asan() { clang++ -std=c++20 -g -fsanitize=address,undefined -fno-omit-frame-pointer "$@" && ./a.out; }
tsan() { clang++ -std=c++20 -g -fsanitize=thread -fno-omit-frame-pointer "$@" && ./a.out; }
# Leak check with Apple's tool (LeakSanitizer is unavailable on macOS).
# usage: memcheck ./a.out [args]
memcheck() { MallocStackLogging=1 leaks --atExit -- "$@"; }
