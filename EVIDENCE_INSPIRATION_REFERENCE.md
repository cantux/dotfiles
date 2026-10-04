# Evidence, inspirations, references

Sources behind the changes recorded in `WORKLOG.md`.

## 2026-09-18 — large-file guards in `.vimrc`

### Primary sources (checked in the installed copies, not from memory)

- `:help profile` — Vim's built-in vimscript profiler. Produced the per-function
  table that named `<SNR>159_PrintTag()` as the cost.
  Vim 9.1, `runtime/doc/repeat.txt`.
- `~/.vim/plugged/tagbar/doc/tagbar.txt`, `*g:tagbar_file_size_limit*` (line
  1134) — documents the byte-count threshold and the `:TagbarForceUpdate`
  override.
- `~/.vim/plugged/ale/plugin/ale.vim:89` — `g:ale_lint_on_enter` defaults to
  `v:true`; `autoload/ale/events.vim:186` registers the `BufWinEnter` autocmd
  that re-lints on buffer entry.
- `~/.vim/plugged/ale/autoload/ale.vim`, `ale#Var()` — resolves `b:ale_*` before
  `g:ale_*`, which is what makes the buffer-local guard work.
- `/usr/share/vim/vim91/autoload/dist/ft.vim:182`, `FTheader()` — `*.h` becomes
  `cpp` unless `g:c_syntax_for_h` is set. This is why a C header was handed to
  C++ linters.
- `~/.vim/plugged/YouCompleteMe/plugin/youcompleteme.vim:192` —
  `g:ycm_disable_for_files_larger_than_kb`, default 1000.

### Prior art the fix is modelled on

- **LargeFile.vim**, Charles E. Campbell (vim.org script #1506). The canonical
  Vim pattern: a `BufReadPre` autocmd that tests `getfsize(expand('<afile>'))`
  against a threshold and disables expensive per-buffer features. The ALE guard
  here is that pattern, narrowed to one plugin instead of globally turning off
  syntax, undo and swap.
- **YouCompleteMe's own `g:ycm_disable_for_files_larger_than_kb`**. The nearest
  prior art inside this same config: a plugin that already refuses to work on
  files past a byte threshold rather than trying and stalling. Tagbar and ALE
  were the two that lacked an equivalent default, so they got one.

### Method

- Brendan Gregg, *Systems Performance* (2nd ed., 2020), ch. 6 — sampling profile
  of an on-CPU process, and the rule of measuring before attributing. `perf
  record -F 199 -g -p <pid>` gave the first signal (deep `call_user_func`
  recursion, `utfc_ptr2len` hot), which pointed at interpreted vimscript rather
  than file I/O and justified switching to Vim's own profiler for symbol names.
- Differential/ablation measurement: four vimrc variants differing by one plugin
  each, same input file, same harness. This is what separated Tagbar (all of the
  blocking cost) from ALE (background CPU burn, re-armed per buffer switch).

### Parallels in other domains

The Tagbar behaviour — cache the expensive *extraction* but redo the expensive
*render* on every view change — is the classic missing-memoization bug in UI
frameworks: React re-rendering a 100k-row list because the parent's state
changed, fixed by virtualizing so only visible rows are built. Tagbar caches
`s:known_files` by mtime but has no equivalent guard on `RenderContent()`.

### Test input

`bpftool btf dump file /sys/kernel/btf/vmlinux format c` — the BPF CO-RE
workflow described in Andrii Nakryiko, "BPF Portability and CO-RE"
(nakryiko.com, 2020) and in `libbpf`'s documentation. The generated
`vmlinux.h` is the realistic large single-header case being optimised for.

