" VimPlug
"
" Install vim-plug if not found
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
      \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif
"
" Run PlugInstall if there are missing plugins
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
    \| PlugInstall --sync | source $MYVIMRC
    \| endif


call plug#begin('~/.vim/plugged')

Plug 'VundleVim/Vundle.vim'

Plug 'xolox/vim-misc'

Plug 'fholgado/minibufexpl.vim'

Plug 'ycm-core/YouCompleteMe', { 'do': './install.py --clangd-completer' }

Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'

Plug 'xolox/vim-easytags'
Plug 'majutsushi/tagbar'

Plug 'tmhedberg/SimpylFold'

Plug 'romainl/vim-dichromatic'
Plug 'morhetz/gruvbox'

Plug 'kien/ctrlp.vim'
Plug 'mbbill/undotree'

" Async lint engine (cpplint + cppcheck for C/C++; clang-tidy comes via clangd)
Plug 'dense-analysis/ale'

" Google formatter stack (vim-codefmt wraps clang-format, gofmt, etc.)
Plug 'google/vim-maktaba'
Plug 'google/vim-codefmt'
Plug 'google/vim-glaive'

call plug#end()

" Init glaive and set clang-format to Google style (2-space indent, 80-col wrap)
" Guard: skip until plugins are installed (avoids errors on first launch)
if exists('*glaive#Install')
  call glaive#Install()
  Glaive codefmt clang_format_style=Google
endif

" ALE — async C/C++ linting. clang-tidy + compiler diagnostics already come
" from clangd (via YCM, see g:ycm_clangd_args below), so ALE only adds the
" linters clangd lacks: cpplint (Google style) + cppcheck. Let YCM own
" completion/LSP and the location list; ALE shows signs only.
let g:ale_disable_lsp = 1
let g:ale_completion_enabled = 0
let g:ale_set_loclist = 0
let g:ale_set_signs = 1
let g:ale_sign_column_always = 1
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_insert_leave = 1
let g:ale_lint_on_save = 1
let g:ale_linters = {'cpp': ['cpplint', 'cppcheck'], 'c': ['cppcheck']}
let g:ale_cpp_cpplint_options = '--filter=-legal/copyright,-build/include_subdir'
let g:ale_cpp_cppcheck_options = '--enable=warning,style,performance,portability --std=c++20 --inline-suppr'
let g:ale_c_cppcheck_options = '--enable=warning,style,performance,portability --inline-suppr'
" jump ALE results with ]a / [a  (]d / [d stay YCM's, see below)
nnoremap ]a :ALENextWrap<CR>
nnoremap [a :ALEPreviousWrap<CR>


"----------------------------------------------------------------------------------------------------------------------"
" Global Settings
"----------------------------------------------------------------------------------------------------------------------"

set nocompatible              " be iMproved, required
filetype off                  " required

" [global] set nowrap        do not wrap lines (use set wrap! from inside vim to manually toggle this)
set nowrap

" [global] writebackup       make a backup before overwriting a file
" set wb
" [global] backupdir         list of directories for the backup file and swap file
" set bdir=$HOME/.vimbk
" set directory=$HOME/.vimbk

" [global] undodir           directory for persistent undo 
set undodir=$HOME/.vim/vimundo
set undofile

" insert space characters whenever the tab key is pressed
set expandtab
" set number of spaces that <Tab> uses while editing
set tabstop=2
" backspace over an indent removes 2 spaces as one unit
set softtabstop=2
" set number of space characters inserted for indentation
set shiftwidth=2

" enable mouse in all modes so scroll events reach vim (e.g. inside tmux)
set mouse=a
" use SGR mouse protocol: reliable scrolling inside tmux / wide terminals
if has('mouse_sgr')
  set ttymouse=sgr
endif

set smartindent
set ignorecase
set smartcase

set hidden

"----------------------------------------------------------------------------------------------------------------------"
" Appearance 
"----------------------------------------------------------------------------------------------------------------------"
" set color scheme to dark blue 
colorscheme dichromatic
" colorscheme gruvbox
set background=dark

if &term =~ '256color'
  " disable Background Color Erase (BCE) so that color schemes
  " render properly when inside 256-color tmux and GNU screen.
  " see also http://snk.tuxfamily.org/log/vim-256color-bce.html
    set t_ut=
endif

" start with ruler
set ruler

" show title
set title

" syntax on wax off
syntax on

set showcmd                     "Show incomplete cmds down the bottom
set showmode                    "Show current mode down the bottom
set number                      "Line numbers are good
set backspace=indent,eol,start  "Allow backspace in insert mode
set incsearch

set scrolloff=8

set colorcolumn=80
highlight ColorColumn ctermbg=0 guibg=lightgrey

"----------------------------------------------------------------------------------------------------------------------"
" Mappings
"
"" block commenting
noremap <F2> :call Comment()<CR>
noremap <F3> :call Uncomment()<CR>

" CTRL-Z is Undo; not in cmdline though
noremap <C-Z> u
inoremap <C-Z> <C-O>u

" CTRL-Y is Redo in normal mode (native <C-R> also works).
" Insert-mode <C-Y> intentionally left unmapped: lets YCM accept a completion
" with <C-y>, and restores native <C-Y> (copy char from the line above).
noremap <C-Y> <C-R>

" map for quick "change to current directory"
map ,cd :cd %:p:h<CR>

nnoremap <silent> <F5> :TagbarToggle<CR>

" shortcut to open NERDTree
nnoremap <F6> :NERDTreeToggle<CR>

let g:ctrlp_map = '<C-p>'
let g:ctrlp_cmd = 'CtrlP'

noremap <C-Down>  <C-W>j
noremap <C-Up>    <C-W>k
noremap <C-Left>  <C-W>h
noremap <C-Right> <C-W>l

" Insert-mode word editing
" keep <Esc> snappy since the Option-key sequence starts with ESC
set ttimeout ttimeoutlen=30
" Option+Backspace: delete the word before the cursor.
" Needs terminal 'Option as Meta'; it then sends ESC + DEL. Map both the
" <M-BS> notation and the raw ESC+DEL bytes so it works either way.
inoremap <M-BS> <C-w>
execute "inoremap \<Esc>\<Char-0x7f> \<C-w>"
" Ctrl+Left / Ctrl+Right: skip back/forward one word (xterm-keys passes these via tmux)
inoremap <C-Left>  <C-o>b
inoremap <C-Right> <C-o>w

let py_template = [
            \"#!/usr/bin/env python",
            \"",
            \"def fnc():",
            \"    return None",
            \"",
            \"def test():",
            \"    assert fnc() == None",
            \"",
            \"if __name__ == \"__main__\":",
            \"    test()",
            \""
            \]
inoremap <C-T> <C-o>:set paste<CR><C-o>:call append(line('$'), py_template)<CR><C-o>:set nopaste<CR>

command FormatJson %!python3 -m json.tool

"----------------------------------------------------------------------------------------------------------------------"
" Autocommands
"----------------------------------------------------------------------------------------------------------------------"

augroup vimrc_autocmds
  autocmd!
  " Convert any literal tabs to spaces on save (expandtab only affects new
  " input). Skip filetypes that REQUIRE real tabs.
  autocmd BufWritePre * if &expandtab && index(['make','go'], &filetype) < 0 | retab | endif
augroup END


"----------------------------------------------------------------------------------------------------------------------"
" Plugins
"----------------------------------------------------------------------------------------------------------------------"
" MiniBufExplorer
let g:miniBufExplModSelTarget = 1
let g:miniBufExplBuffersNeeded = 1

" TagBar
let tagbar_ctags_bin='/opt/homebrew/bin/ctags'
" autocmd vimenter * TagbarOpen
autocmd VimEnter * nested :TagbarOpen

set tags=tags,./tags

" External source trees (glibc, kernel) for tag + cscope navigation.
" Build indexes with: (kernel) gmake ARCH=x86_64 tags cscope ; (glibc) ctags -R . && cscope -Rbq
set tags+=~/src/glibc/tags,~/src/linux/tags
if has('cscope')
  set cscopetag           " :tag and <C-]> also consult cscope
  set csto=1              " try ctags first, then cscope
  silent! cs add ~/src/glibc/cscope.out ~/src/glibc
  silent! cs add ~/src/linux/cscope.out ~/src/linux
  " cscope queries on the word under the cursor:
  nnoremap <leader>fg :cs find g <C-r><C-w><CR>   " global definition
  nnoremap <leader>fs :cs find s <C-r><C-w><CR>   " all symbol occurrences
  nnoremap <leader>fc :cs find c <C-r><C-w><CR>   " callers of this function
  nnoremap <leader>fd :cs find d <C-r><C-w><CR>   " functions this one calls
endif
" EasyTags
let g:easytags_cmd = '/opt/homebrew/bin/ctags'
let g:easytags_auto_update = 0
let g:easytags_always_enabled = 0
let g:easytags_auto_highlight = 0
let g:easytags_suppress_ctags_warning = 1

" NERDTree
" close vim if the only window left open is a NERDTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" Open NERDTree when vim starts
let g:NERDTreeDirArrowExpandable = '+'
let g:NERDTreeDirArrowCollapsible = '-'

augroup NERD
    au!
    autocmd VimEnter * NERDTree
    autocmd VimEnter * wincmd p
augroup END

" CtrlP
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*/build/*,*/dist/*
let g:ctrlp_working_path_mode = 'ra'

" YCM
let g:ycm_collect_identifiers_from_tags_files=1
" Run clang-tidy inside clangd (checks configured in ~/.config/clangd/config.yaml);
" don't auto-insert #includes on completion.
let g:ycm_clangd_args = ['--clang-tidy', '--header-insertion=never']
let mapleader = ","

nnoremap <leader>g :YcmCompleter GoTo<CR>
nnoremap <leader>r :YcmCompleter GoToReferences<CR>
nnoremap <leader>def :YcmCompleter GoToDefinition<CR>
nnoremap <leader>dec :YcmCompleter GoToDeclaration<CR>

" clangd / YCM power maps (keys picked to not extend ,g or ,r)
nnoremap <leader>i  :YcmCompleter GoToImplementation<CR>
nnoremap <leader>a  :YcmCompleter GoToAlternateFile<CR>
nnoremap <leader>t  :YcmCompleter GetType<CR>
nnoremap <leader>T  :YcmCompleter GoToType<CR>
nnoremap <leader>o  :YcmCompleter GoToDocumentOutline<CR>
nnoremap <leader>D  :YcmCompleter GetDoc<CR>
nnoremap <leader>F  :FormatCode<CR>
vnoremap <leader>F  :FormatLines<CR>
nnoremap <leader>R  :YcmCompleter RefactorRename<Space>
nnoremap <leader>fx :YcmCompleter FixIt<CR>
nnoremap <leader>ca :YcmCompleter GoToCallers<CR>
nnoremap <leader>ce :YcmCompleter GoToCallees<CR>
nnoremap <leader># :YcmCompleter GoToInclude<CR>
nmap     <leader>h  <plug>(YCMHover)

" Diagnostics: move detailed-message off ,d (clashed with ,def/,dec) to ,dd,
" send diagnostics to the location list, jump with ]d / [d.
let g:ycm_key_detailed_diagnostics = '<leader>dd'
let g:ycm_always_populate_location_list = 1
nnoremap ]d :lnext<CR>
nnoremap [d :lprev<CR>

" Insert the C++ Makefile skeleton at the top of the file (real tabs preserved).
nnoremap <leader>mk :0read ~/.vim/templates/Makefile<CR>


"

"----------------------------------------------------------------------------------------------------------------------"
" Custom Functions
"----------------------------------------------------------------------------------------------------------------------"

" Comments range (handles multiple file types) 
function! Comment() range 
  if &filetype == "c" || &filetype == "php" || &filetype == "css" 
    execute ":" . a:firstline . "," . a:lastline . 's/^\(.*\)$/\/\* \1 \*\//' 
  elseif &filetype == "html" || &filetype == "xml" || &filetype == "xslt" || &filetype == "xsd" 
    execute ":" . a:firstline . "," . a:lastline . 's/^\(.*\)$/<!-- \1 -->/' 
  else 
    if &filetype == "java" || &filetype == "cpp" || &filetype == "cs" 
      let commentString = "\\/\\/" 
    elseif &filetype == "vim" 
      let commentString = '"' 
    elseif &filetype == "sql" 
      let commentString = '--' 
    else 
      let commentString = "#" 
    endif 
    execute ":" . a:firstline . "," . a:lastline . 's/^/' . commentString . ' /' 
  endif 
endfunction 

" Uncomments range (handles multiple file types) 
function! Uncomment() range 
  if &filetype == "c" || &filetype == "php" || &filetype == "css" || &filetype == "html" || &filetype == "xml" || &filetype == "xslt" || &filetype == "xsd" 
    " http://www.vim.org/tips/tip.php?tip_id=271 
    execute ":" . a:firstline . "," . a:lastline . 's/^\([/(]\*\|<!--\) \(.*\) \(\*[/)]\|-->\)$/\2/' 
  else 
    if &filetype == "java" || &filetype == "cpp" || &filetype == "cs" 
      let commentString = "\\/\\/" 
    elseif &filetype == "vim" 
      let commentString = '"' 
    elseif &filetype == "sql" 
      let commentString = '--' 
    else 
      let commentString = "#" 
    endif 
    execute ":" . a:firstline . "," . a:lastline . 's/^' . commentString . ' //' 
  endif 
endfunction 

command! -complete=shellcmd -nargs=+ Shell call s:RunShellCommand(<q-args>)
function! s:RunShellCommand(cmdline)
  echo a:cmdline
  let expanded_cmdline = a:cmdline
  for part in split(a:cmdline, ' ')
     if part[0] =~ '\v[%#<]'
        let expanded_part = fnameescape(expand(part))
        let expanded_cmdline = substitute(expanded_cmdline, part, expanded_part, '')
     endif
  endfor
  botright new
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
  call setline(1, 'You entered:    ' . a:cmdline)
  call setline(2, 'Expanded Form:  ' .expanded_cmdline)
  call setline(3,substitute(getline(2),'.','=','g'))
  execute '$read !'. expanded_cmdline
  setlocal nomodifiable
  
endfunction


