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

# Open Claude in a new git worktree with a tmux session.
# Usage: ccw <worktree-name> [extra claude flags]
ccw() { claude --tmux=classic --worktree "$@"; }

# C++ static analysis. dnf's clang-tools-extra / clang-analyzer put clang-tidy
# and scan-build on PATH, so no aliases are needed (unlike keg-only mac llvm).

# C++ sanitizer build+run helpers. ASan/UBSan/TSan work out of the box.
# (MSan is omitted: it needs the whole program -- incl. the C++ stdlib --
# instrumented, and el10 ships no instrumented libc++, so it false-positives in
# libstdc++. Use valgrind/memcheck below for uninitialized-read style bugs.)
# usage: asan foo.cpp   (builds with ASan+UBSan, then runs ./a.out)
asan() { clang++ -std=c++20 -g -fsanitize=address,undefined -fno-omit-frame-pointer "$@" && ./a.out; }
tsan() { clang++ -std=c++20 -g -fsanitize=thread -fno-omit-frame-pointer "$@" && ./a.out; }
# Leak/error check via valgrind (replaces Apple's `leaks`).
# usage: memcheck ./a.out [args]
memcheck() { valgrind --leak-check=full --show-leak-kinds=all "$@"; }
