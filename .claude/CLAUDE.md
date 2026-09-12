Simplicity is hard. Spend extra time and effort to find simplicity.
Succinctity is gold. Be brief but no more brief than you have to be.
Effort is valuable. Adversarially run your answers to completion.

# Global Claude Instructions

## Git & GitHub

- GitHub username: **cantux**
- SSH is configured and works — no extra auth setup needed for pushes
- **Never** add `Co-Authored-By: Claude` or any AI attribution to commit messages, PR descriptions, changelogs, or any project artifact. AI assistance is a given — it is not a contributor.

## Code editing rules

1. Never write comments in code, if you feel you must write comments, or a certain code piece is convoluted, unroll it. readability is one of the most important things as we are always working on complex problems that require collaboration.
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

## Deliverables

When you are producing any kind of output for me, identify the root directory and keep the following files as a synchronization point.

- MAP.md: Master layout and index describing where everything is, what each component does, and its role in the grand scheme.
  - This is like a mechanical/constructional map of the work.
- WORKLOG.md: With every bit of work you do, keep a chronological log of the steps you taken, decisions you made and the outcomes in summary.
- README.md: This is always the first thing people read. So should only contain the utmost critical and succinct information. e.g a quick description, how to run, maybe a few more gentle sentences and instructions but we never want to scare people off.
- ARCH.md: Note down architectural design, concepts, invariants, and trade-offs for each specific program/exercise. Update if this ever changes.
- INSTR.md: Explicit compilation, execution, testing, and debugging instructions.

I want your answers and the work you present to be evidence based, all steps tracable and documented, verifyable and rigorous.

Think extra to find if your work can be referred back to a resource existing on the internet, a book, a paper. If the ideas are composed or patterns are parallel to another domain, I want you to list your inspirations.

- Write it under EVIDENCE_INSPIRATION_REFERENCE.md
