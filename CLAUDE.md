# System config changes

Dotfiles for this machine are tracked in `~/Projects/dotfiles`, on the branch
matching this machine's platform (this box: CentOS Stream 10 -> branch `centos`).

Any file that repo's `sync.sh` tracks (check its `items` list for the exact
set — currently things like `.bashrc`, `.tmux.conf`, `.vimrc`, `.gitconfig`,
`.config/kitty/kitty.conf`, `.claude/keybindings.json`, `.claude/settings.json`)
must be edited there first, then applied with `./sync.sh` — never edited
directly under `$HOME`. A direct edit under `$HOME` will be silently
overwritten the next time `sync.sh` runs (it does `rsync --delete`, not a merge).

`sync.sh` also fans the agent prompt out from one source: `.claude/CLAUDE.md`
becomes `~/.claude/CLAUDE.md` (`claude`), `~/.codex/AGENTS.md` (`codex`) and
`~/.gemini/config/rules/GEMINI.md` (`agy`), and this file becomes `~/CLAUDE.md`
plus `~/AGENTS.md`. Those generated copies get overwritten too — edit the repo.

See `~/Projects/dotfiles/README.md` for the full workflow (reload commands,
etc).
