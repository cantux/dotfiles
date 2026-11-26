# PLAN

## Goal

Extend the vim C++ Makefile template (`.vim/templates/Makefile`, inserted by
`,mk`) with check targets: AddressSanitizer with UndefinedBehaviorSanitizer,
ThreadSanitizer, Valgrind Memcheck, Helgrind, three compiler-warning levels,
clang-tidy, cppcheck, cpplint, a format check, and an aggregate `check`.
Deploy the template to this machine without a full `sync.sh`, because the
deployed `~/.claude/settings.json` and `~/.codex/config.toml` hold runtime
edits newer than the repo copies.

## Units

| # | Unit | Check that shows it done | State |
|---|---|---|---|
| 1 | Template targets, committed on `centos` | Scratchpad test bed: every defect class fails its target; the formatted gtest skeleton and the split layout pass `make check` | done |
| 2 | Merge `centos` into `centos_xps_9700` | `git diff --cached` is empty; `git status` lists the same uncommitted paths and added lines as before the merge | done |
| 3 | Deploy `.vim` with the rsync that `sync.sh` runs for that item | The dry run lists only `templates/Makefile`; `cmp` of the repo template and `~/.vim/templates/Makefile` succeeds | done |
