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
set tabstop=4
" set number of space characters inserted for indentation
set shiftwidth=4

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

" CTRL-Y is Redo (although not repeat); not in cmdline though
noremap <C-Y> <C-R>
inoremap <C-Y> <C-O><C-R>

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


"----------------------------------------------------------------------------------------------------------------------"
" Autocommands
"----------------------------------------------------------------------------------------------------------------------"


"----------------------------------------------------------------------------------------------------------------------"
" Plugins
"----------------------------------------------------------------------------------------------------------------------"
" MiniBufExplorer
let g:miniBufExplModSelTarget = 1
let g:miniBufExplBuffersNeeded = 1

" TagBar
let tagbar_ctags_bin='~/.ctags/uctags_bin/bin/ctags'
" autocmd vimenter * TagbarOpen
autocmd VimEnter * nested :TagbarOpen

set tags=tags,./tags
" EasyTags
let g:easytags_cmd = '~/.ctags/uctags_bin/bin/ctags'
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
let mapleader = ","

nnoremap <leader>g :YcmCompleter GoTo<CR>
nnoremap <leader>r :YcmCompleter GoToReferences<CR>
nnoremap <leader>def :YcmCompleter GoToDefinition<CR>
nnoremap <leader>dec :YcmCompleter GoToDeclaration<CR>


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

Plug 'ycm-core/YouCompleteMe', { 'commit':'d98f896' }

Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'

Plug 'xolox/vim-easytags'
Plug 'majutsushi/tagbar'

Plug 'tmhedberg/SimpylFold'

Plug 'romainl/vim-dichromatic'
Plug 'morhetz/gruvbox'

Plug 'kien/ctrlp.vim' 
Plug 'mbbill/undotree'

call plug#end()
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


