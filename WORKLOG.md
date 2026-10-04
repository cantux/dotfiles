# WORKLOG

Chronological record of changes to this repo, with the evidence behind them.

## 2026-09-18 — vim: 90+ s to open a large generated header

### Symptom

Opening `vmlinux.h` (bpftool-generated BTF header) took ~1 minute. Switching
away to another buffer and back cost the same again.

### Measurement setup

Test file generated on this box:

```
bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h   # 3.0 MB, 143355 lines
```

Method: run vim under `tmux new-session -d`, sample `utime+stime` from
`/proc/<pid>/stat` once per second, and count the interval where vim burns CPU.
External tools (`ctags`, `cpplint`) were replaced by logging shims to count
invocations. Variant vimrcs isolated one plugin at a time.

### Results

Reading the file is not the problem: `vim -u NONE` opens the 30 MB stress copy
in 0.11 s. `syntax on` adds nothing measurable; `undofile` adds 0.12 s.

| config (3 MB vmlinux.h)        | open   | switch back |
|--------------------------------|--------|-------------|
| full vimrc                     | 102 s  | 20 s        |
| Tagbar auto-open removed       | 0.26 s | 0 s         |
| ALE disabled, Tagbar kept      | 86 s   | —           |
| both removed                   | 0.23 s | 0 s         |

`:profile` over one buffer switch named the cost directly:

```
count     total (s)      self (s)  function
103431  26.885739025  20.844805500  <SNR>159_PrintTag()
    10  17.563466823   0.001159982  <SNR>159_AutoUpdate()
     2  17.514635736   0.085219126  <SNR>159_RenderContent()
     2  17.424942964   0.403639682  <SNR>159_PrintKinds()
```

`ctags` itself is cheap (0.39 s on 3 MB, 3.97 s on 30 MB) and ran exactly once.
The cost is Tagbar re-printing all 103431 tags into its sidebar — one vimscript
function call per tag — every time the current buffer changes.

Second, independent cost: vim maps `*.h` to filetype `cpp` (`dist#ft#FTheader`,
no `g:c_syntax_for_h` set), so ALE ran the C++ linters. On 3 MB, `cpplint`
takes 23.2 s and `cppcheck` had not finished at 900 s. `g:ale_lint_on_enter`
defaults to true and was never overridden, and ALE registers
`autocmd BufWinEnter * call ale#events#LintOnEnter()`, so both restart on every
buffer switch. Verified with a shim: 3 buffer switches produced 3 cpplint runs.

YCM was not a factor — `g:ycm_disable_for_files_larger_than_kb` defaults to
1000 KB, so it already skips these files.

### Change

`.vimrc`, two additions, both with documented escape hatches:

```vim
let g:tagbar_file_size_limit = 1024 * 1024      " :TagbarForceUpdate overrides

augroup ale_skip_huge_files
  autocmd!
  autocmd BufReadPre * if getfsize(expand('<afile>')) > 1024 * 1024
        \ | let b:ale_enabled = 0
        \ | endif
augroup END
```

`ale#Var()` reads `b:ale_enabled` before `g:ale_enabled`, so the buffer-local
flag is honoured; `:ALEToggleBuffer` re-enables linting for that buffer.

### After

| file                | open  | switch back | ctags | cpplint |
|---------------------|-------|-------------|-------|---------|
| vmlinux.h (3 MB)    | 1 s   | 0 s         | 0     | 0       |
| vmlinux30.h (30 MB) | 0 s   | 0 s         | 0     | 0       |

Regression check: a normal `.cpp` file still gets its Tagbar tree rendered and
still runs cpplint.

