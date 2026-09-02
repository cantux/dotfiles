# Global Claude Instructions

## Git & GitHub

- GitHub username: **cantux**
- SSH is configured and works — no extra auth setup needed for pushes
- **Never** add `Co-Authored-By: Claude` or any AI attribution to commit messages, PR descriptions, changelogs, or any project artifact. AI assistance is a given — it is not a contributor.

## Code editing rules

1. Never write comments in code.
2. Never change existing variable names unless you are changing the logic.
3. Never change the existing order of the code unless it is absolutely necessary.

## Environment updates

- Every environment/config change on this machine — anything `sync.sh` tracks, including this file — is made in `~/Projects/dotfiles` on the platform branch (this box: `centos`), then applied with `./sync.sh`. Never edit tracked files directly under `$HOME`; sync.sh rsyncs over them.

## Plan mode

- In plan mode, always show the exact diff of every proposed change (old lines / new lines) in the plan and in the chat — never just a prose description of the edit.
