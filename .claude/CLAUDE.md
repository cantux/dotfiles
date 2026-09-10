# Global Claude Instructions

## Git & GitHub

- GitHub username: **cantux**
- SSH is configured and works — no extra auth setup needed for pushes
- **Never** add `Co-Authored-By: Claude` or any AI attribution to commit messages, PR descriptions, changelogs, or any project artifact. AI assistance is a given — it is not a contributor.

## Code editing rules

1. Never write comments in code.
2. Never change existing variable names unless you are changing the logic.
3. Never change the existing order of the code unless it is absolutely necessary.
4. C++: never use std::ranges or std::views in solutions or examples — classic STL algorithms and explicit loops only.
5. C++: no exceptions — never throw or write try/catch; report failure through return values and error codes (std::from_chars-style, std::optional, sentinel returns).
6. Name by single meaning: for every variable, function, and term, pick the word with exactly one interpretation over any colorful, idiomatic, or metaphorical synonym (bookkeeping_ptr, not stash_ptr; remainder, not leftover). Test before using a name: if two readers could picture two different things, the name is wrong — find the one-meaning word.

## Writing style

- Direct, active voice only — never passive. Prefer procedural language: numbered steps, lists, named components. Explain by decomposing a whole into parts and composing parts back into the whole. Do not invent formalisms ("the contract", "the mechanism") unless the source material uses them.

## Environment updates

- Every environment/config change on this machine — anything `sync.sh` tracks, including this file — is made in `~/Projects/dotfiles` on the platform branch (this box: `centos`), then applied with `./sync.sh`. Never edit tracked files directly under `$HOME`; sync.sh rsyncs over them.

## Plan mode

- In plan mode, always show the exact diff of every proposed change (old lines / new lines) in the plan and in the chat — never just a prose description of the edit.
