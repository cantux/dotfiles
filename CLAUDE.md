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

# Where programs live

- Prefer a package over a download. Check `rpm -qf <path>`, then
  `dnf provides '*/bin/<name>'` across BaseOS, AppStream, CRB, EPEL and the
  configured vendor repositories (pkgs.k8s.io, Docker CE), then
  `snap find <name>`. Download only when no package exists (kind) or when a
  project pins a version no package provides.
- `~/Downloads` receives the download itself: tarball, AppImage, installer
  script, archive.
- `~/Applications` receives what a download unpacks or installs into: the
  extracted directory, the standalone binary, the integrated AppImage. Give
  installers that accept a target directory `~/Applications`. AppImageLauncher
  already integrates into it and its daemon watches it; non-AppImage files
  there are ignored.
- `~/.local/bin` is on PATH (`.bashrc`). Self-installing tools (pipx, claude,
  codex, agy) put themselves there; leave them. Expose a program from
  `~/Applications` with a symlink: `ln -s ~/Applications/foo/foo
  ~/.local/bin/foo`. Keep `~/Applications` off PATH.
- Manager-owned installs stay where their manager put them: dnf (`/usr`),
  rustup (`~/.cargo/bin`), npm (`~/.npm-global/bin`).
