syntax clear

syn match   pasmComment "#.*$" contains=pasmTodo,@Spell
syn keyword pasmTodo   TODO FIXME contained

syn keyword pasmInstr    mov mvri movhlt 
syn keyword pasmInstr    extr dep 
syn keyword pasmInstr    add sub
syn keyword pasmInstr    or and sll slr 
syn keyword pasmInstr    st st8 st16 st32 
syn keyword pasmInstr    st8 st16 st32 
syn keyword pasmInstr    jmp jeq jne
syn keyword pasmInstr    hlt
syn keyword pasmInstr    ld ld8 ld16 ld32
syn keyword pasmInstr    pst pld pldu
syn keyword pasmInstr    hash0 hash1 hash2 hash3
syn keyword pasmInstr    ff1 ff0
syn keyword pasmInstr    yield nop
syn keyword pasmInstr    psave por pand
syn keyword pasmInstr    mmac
syn keyword pasmInstr    linit
syn keyword pasmSpecReg  rpos0 rpos1 lfsr loopcnt rm1 rsink tid tsc wtime rz

syn match pasmTstInstr     /tst\(eq\|neq\|bc\)/
syn match pasmMainMemInstr /mmst\(16\|32\|64\|128\)\?/
syn match pasmPredicate    /\(\s\|!\|=\)p[01234567]\(\s\|,\|=\?\)/
syn match pasmLabel          "\v^\s*\w*:"

syn region pasmCsubDef   start=".entpt" end="$" 

if version >= 508 || !exists("did_pasm_syn_inits")
  if version <= 508
    let did_pasm_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink pasmTodo               Todo
  HiLink pasmComment            Comment   
  HiLink pasmCsubDef            WildMenu

  HiLink pasmInstr              ModeMsg
  HiLink pasmTstInstr           ModeMsg
  HiLink pasmMainMemInstr       ModeMsg
  HiLink pasmLabel              Underlined 
  HiLink pasmPredicate          Identifier
  HiLink pasmSpecReg            Identifier
   

  delcommand HiLink
endif

let b:current_syntax = "pasm"

