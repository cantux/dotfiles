syn keyword     uasmTodo   contained TODO FIXME
syn match uasmComment /#.\?/
syn match uasmLabel  /^\s\?\w\+:/

syn keyword identifier mov 
syn keyword identifier extr dep 
syn keyword identifier or and sll slr 
syn keyword identifier st st8 st16 st32 
syn keyword identifier ld ld8 ld16 ld32
syn keyword identifier pst pld pldu


HiLink uasmTodo               Todo
HiLink uasmComment            Comment   
HiLink uasmLabel              Label   
