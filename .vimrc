" set nocompatible
" source $VIMRUNTIME/vimrc_example.vim
"source $VIMRUNTIME/mswin.vim

"----------------------------------------------------------------------------------------------------------------------"
" Global Settings
"----------------------------------------------------------------------------------------------------------------------"

" [global] set nowrap        do not wrap lines (use set wrap! from inside vim to manually toggle this)
  set nowrap

" [global] writebackup       make a backup before overwriting a file
  set wb

" [global] backupdir         list of directories for the backup file and swap file
  if (&term == "win32" || "pcterm" || has("gui_win32"))
    set bdir=$VIM\backup
    set directory=$VIM\backup
  else
    set bdir=$HOME/tmp/.vimbk
    set directory=$HOME/tmp/.vimbk
  endif

" [global] undodir           directory for persistent undo 
  if (&term == "win32" || "pcterm" || has("gui_win32"))
    set undodir=$VIM\undo
  else
    set undodir=$HOME/tmp/.vimundo
  endif
 
" insert space characters whenever the tab key is pressed
    set expandtab
			
" set number of spaces that <Tab> uses while editing
    set tabstop=4

" set number of space characters inserted for indentation
    set shiftwidth=4

" set gui font
    " set guifont=Lucida_Console:h9:cANSI
    set guifont=Bitstream\ Vera\ Sans\ Mono\ 9
autocmd BufRead *.py set smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class 
autocmd BufRead *.ipy set smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class 

"----------------------------------------------------------------------------------------------------------------------"
" Appearance 
"----------------------------------------------------------------------------------------------------------------------"
" set color scheme to dark blue 
colorscheme slate

" start with ruler
set ruler

" show title
set title
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
  1
endfunction

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
" CTRL-A CTRL-I mapped to F8 (used to switch between screen shell and edited
" files)
noremap <F8> <C-A><C-I>
" map for quick "change to current directory"
map ,cd :cd %:p:h<CR>

nnoremap <silent> <F9> :TagbarToggle<CR>

" shortcut to open NERDTree
nnoremap <F10> :NERDTreeToggle<CR>

let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'

" ca bdelete bd

"----------------------------------------------------------------------------------------------------------------------"
" Autocommands
"----------------------------------------------------------------------------------------------------------------------"

" In text files, always limit the width of text to 78 characters.
"autocmd BufRead *.txt set textwidth=78

au BufRead,BufNewFile *.stil    setfiletype stil
au BufRead,BufNewFile *.tcl    setfiletype tcl
au BufRead,BufNewFile *.pasm   setfiletype pasm
au BufRead,BufNewFile *.pasm   set syntax=pasm

" au BufRead,BufNewFile *.[ch]      set tabstop=2 
" au BufRead,BufNewFile *.[ch]      set shiftwidth=2 
au BufRead,BufNewFile *.c      set tabstop=2 
au BufRead,BufNewFile *.c      set shiftwidth=2 
au BufRead,BufNewFile *.cpp      set tabstop=4 
au BufRead,BufNewFile *.cpp      set shiftwidth=4 

" Force a syntax highlighting sync when you enter a buffer
" Normally syntax is cached so this is useful when developing syntax files
autocmd BufEnter * :syntax sync fromstart


" Print Options "
set popt=paper:letter

"----------------------------------------------------------------------------------------------------------------------"
" Plugins
"----------------------------------------------------------------------------------------------------------------------"
" MiniBufExplorer
let g:miniBufExplMapWindowNavVim = 1
let g:miniBufExplMapWindowNavArrows = 1
let g:miniBufExplMapCTabSwitchBufs = 1
let g:miniBufExplModSelTarget = 1

" TagBar
let tagbar_ctags_bin='/home/ctuksavul/.ctags/uctags_bin/bin/ctags'

" TagList
let Tlist_Ctags_Cmd='/home/ctuksavul/.ctags/uctags_bin/bin/ctags'
" show tag drop down menu in GVIM
let Tlist_Show_Menu = 1 
" default behavior is sort by name
let Tlist_Sort_Type = 'name'

" TagBar
let tagbar_ctags_bin='/home/ctuksavul/.ctags/uctags_bin/bin/ctags'

" EasyTags
let g:easytags_cmd = '/home/ctuksavul/.ctags/uctags_bin/bin/ctags'
let g:easytags_file = '/home/ctuksavul/.ctags/tags'
let g:easytags_auto_update = 0
let g:easytags_always_enabled = 0
let g:easytags_by_filetype = '/home/ctuksavul/.ctags/tags'
let g:easytags_auto_highlight = 0

" NERDTree
" close vim if the only window left open is a NERDTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" Open NERDTree when vim starts
autocmd vimenter * NERDTree


" CtrlP
set runtimepath^=~/.vim/bundle/ctrlp.vim
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*/build/*,*/dist/*

set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'
Plugin 'Valloric/YouCompleteMe'

call vundle#end()            " required
filetype plugin indent on    " required
