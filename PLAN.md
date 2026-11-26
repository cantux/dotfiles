# PLAN

## Goal

Every indentation that the dotfiles author or generate uses 2 spaces: the
gtest skeleton, the Python skeleton of `.vimrc` (`py_template`), the JSON that
`:FormatJson` writes, `.gitconfig`, and `containers/Containerfile.agy-dev`.
Deploy the changed items only, because the deployed `~/.claude/settings.json`
and `~/.codex/config.toml` hold runtime edits newer than the repo copies.

## Units

| # | Unit | Check that shows it done | State |
|---|---|---|---|
| 1 | 2-space edits, committed on `centos` | `clang-format --dry-run --Werror` accepts `gtest.cpp` and `make check` passes on the unmodified skeleton; `py_template` yields 2-space Python that runs; `:FormatJson` writes 2-space JSON; `git config --list` of `.gitconfig` and the joined `RUN` command of the Containerfile are unchanged; the indentation scan finds no 4-space authored file | done |
| 2 | Merge `centos` into `centos_xps_9700` | `git diff --cached` is empty; `git status` is unchanged; the edited log files equal their pre-merge content followed by the appended text | open |
| 3 | Deploy `.vim`, `.vimrc` and `.gitconfig` as `sync.sh` does | The `.vim` dry run lists only `templates/gtest.cpp`; `cmp` of each repo file and its deployed copy succeeds | open |
