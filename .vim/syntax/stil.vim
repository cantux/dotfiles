" Vim syntax file
" Language:     STIL
" Maintainer:   
" Filenames:    *.stil
" Last Change:  24th April 2002
" URL:          http://www.netcomuk.co.uk/~mrw/vim/syntax

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

"syn match stilSpecialChar "[!@#$%^&\*()-+=|`~{[}\]:;',<.>/?\\]"

" STIL comments
syn keyword     stilTodo        contained TODO FIXME XXX
syn region      stilComment     start="/\*" end="\*/" contains=stilTodo
syn match       stilComment     "//.*$" contains=stilTodo

" STIL number forms
syn match stilInteger "-\d\+"
syn match stilInteger "\<\d\+"
syn match stilHex "\<\x\+\>" contains=stilEngUnits
syn match stilDecimal "-\=\d\+\.\d\+"
syn match stilDecimal "-\=\d\+e-\=\d\+"
syn match stilDecimal "-\=\d\+\.\d\+e-\=\d\+"

" STIL engineering units
syn match stilEngUnits "[EPTGMkmunpfa]\=\(A\|Cel\|F\|H\|Hz\|m\|Ohm\|s\|W\|V\)\>"

" STIL identifiers
syn match stilIdentifier "\<\h\w*\>"
syn match stilDomain "\<\h\w*\>\s\+{"me=e-1

" STIL strings
syn match stilStringDelim +"+
syn region stilString matchgroup=stilStringDelim start=+"+ end=+"+

" STIL annotations (highlighted as String)
syn match stilAnnDelim "\<Ann{\*"
syn match stilAnnDelim "\*}"
syn region stilAnn   matchgroup=stilAnnDelim start=+\<Ann{\*+ end=+\*}+ contains=stilInteger,stilDecimal

" STIL reserved words
syn keyword stilStatement STIL

syn keyword stilStatement Header Title Date Source History

syn keyword stilStatement Include IfNeed

syn keyword stilStatement UserKeywords

syn keyword stilStatement UserFunctions

syn keyword stilStatement Signals
syn keyword stilStatement In Out InOut Supply Pseudo
syn keyword stilStatement ScanIn ScanOut Base Alignment DataBitCount
syn keyword stilStatement Termination TerminateHigh TerminateLow TerminateOff TerminateUnknown
syn keyword stilStatement ForceUp ForceDown ForceOff U D Z
syn keyword stilStatement  Hex Dec
syn keyword stilStatement MSB LSB

syn keyword stilStatement SignalGroups
syn match stilSigExprDelim +'+
syn region stilSigExpr matchgroup=stilSigExprDelim start=+'+ end=+'+ contains=stilIdentifier,stilInteger,stilEngUnits

syn keyword stilStatement PatternExec
syn keyword stilStatement Timing PatternBurst Category Selector

syn keyword stilStatement PatternBurst
syn keyword stilStatement Start Stop PatList

syn keyword stilStatement Timing
syn keyword stilStatement WaveformTable Period Waveforms InheritWaveformTable SubWaveforms InheritWaveform Duration
syn keyword stilStatement ForcePrior CompareLow CompareHigh CompareUnknown CompareOff CompareValid
syn keyword stilStatement CompareLowWindow CompareHighWindow CompareOffWindow CompareValidWindow
syn keyword stilStatement ForceUnknown LogicLow LogicHigh LogicZ Unknown ExpectHigh ExpectLow ExpectOff Marker
syn keyword stilStatement P L H x X T V l h t v N A B F G R Q M
syn match stilStatement "?"
syn keyword stilStatement min max

syn keyword stilStatement Spec
syn keyword stilStatement Variable
syn keyword stilStatement Min Max Type Meas

syn keyword stilStatement ScanStructures
syn keyword stilStatement ScanChain
syn keyword stilStatement ScanLength ScanOutLength ScanCells ScanMasterClock ScanSlaveClock ScanInversion

syn keyword stilStatement Pattern
syn keyword stilStatement BreakPoint Infinite Call Macro GoTo Stop IddqTestPoint TimeUnit
syn keyword stilRepeat   Loop MatchLoop 
syn keyword stilStatement Vector Condition

syn keyword stilStatement Procedures
syn keyword stilStatement Shift

syn keyword stilStatement MacroDefs


syn match       stilMathOperator "[-+\*/@]"
syn match       stilLogicalOperator "[<>]"
syn match       stilLogicalOperator "[!<>]="

" try comment handling from c
if exists("c_comment_strings")
  " A comment can contain cString, cCharacter and cNumber.
  " But a "*/" inside a cString in a cComment DOES end the comment!  So we
  " need to use a special type of cString: cCommentString, which also ends on
  " "*/", and sees a "*" at the start of the line as comment again.
  " Unfortunately this doesn't very well work for // type of comments :-(
  syntax match	cCommentSkip	contained "^\s*\*\($\|\s\+\)"
  syntax region cCommentString	contained start=+L\=\\\@<!"+ skip=+\\\\\|\\"+ end=+"+ end=+\*/+me=s-1 contains=cSpecial,cCommentSkip
  syntax region cComment2String	contained start=+L\=\\\@<!"+ skip=+\\\\\|\\"+ end=+"+ end="$" contains=cSpecial
  syntax region  cCommentL	start="//" skip="\\$" end="$" keepend contains=@cCommentGroup,cComment2String,cCharacter,cNumbersCom,cSpaceError
  syntax region cComment	matchgroup=cCommentStart start="/\*" matchgroup=NONE end="\*/" contains=@cCommentGroup,cCommentStartError,cCommentString,cCharacter,cNumbersCom,cSpaceError
else
  syn region	cCommentL	start="//" skip="\\$" end="$" keepend contains=@cCommentGroup,cSpaceError
  syn region	cComment	matchgroup=cCommentStart start="/\*" matchgroup=NONE end="\*/" contains=@cCommentGroup,cCommentStartError,cSpaceError
endif
" keep a // comment separately, it terminates a preproc. conditional
syntax match	cCommentError	display "\*/"
syntax match	cCommentStartError display "/\*"me=e-1 contained







if version >= 508 || !exists("did_stil_syntax_inits")
  if version < 508
    let did_stil_syntax_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink stilTodo               Todo
  HiLink stilComment Comment
  HiLink stilComment Comment

  HiLink stilInteger Number
  HiLink stilHex    Number
  HiLink stilDecimal Float

  HiLink stilStringDelim Delimiter
  HiLink stilString String

  HiLink stilAnnDelim Delimiter
  HiLink stilAnn   String

  HiLink stilSigExprOp Operator
  HiLink stilSigExprDelim Delimiter
  HiLink stilSigExpr   String

  HiLink stilIdentifier Identifier
  HiLink stilDomain Function

  HiLink stilStatement Statement
  HiLink stilRepeat Repeat

  HiLink stilSpecialChar Special

  HiLink stilMathOperator Operator
  HiLink stilLogicalOperator Operator

  HiLink stilEngUnits PreProc

  delcommand HiLink
endif

let b:current_syntax = "stil"


