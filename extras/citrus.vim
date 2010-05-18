" Vim syntax file for Citrus grammars.
"
" Language: Citrus
" Author: Michael Jackson

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" Grammars are case sensitive.
syn case match

" Include the Ruby grammar for use later.
syn include @rubyTop syntax/ruby.vim

syn match ctDoubleColon "::" contained
syn match ctConstant "\u\w*" contained
syn match ctVariable "\l\w*" contained
syn match ctModule "\(\(::\)\?\u\w*\)\+" contains=ctDoubleColon,ctConstant contained

" Comments
syn match ctComment "#.*" contains=@Spell

" Keywords
syn match ctKeyword "\<super\>" contained

" Terminals
syn region ctString matchgroup=ctStringDelimiter start="\"" end="\"" skip="\\\\\|\\\"" contains=ctStringEscape
syn region ctString matchgroup=ctStringDelimiter start="'" end="'" skip="\\\\\|\\'"
syn region ctRegexp matchgroup=ctRegexpDelimiter start="/" end="/[iomxneus]*" skip="\\\\\|\\/" contained display

syn match ctCharacterClass  "\[\(\\.\|[^\]\\]\)*\]" contained display
syn match ctAnything        "\." contained display

syn match ctStringEscape  "\\\\\|\\[abefnrstv]\|\\\o\{1,3}\|\\x\x\{1,2}" contained display
syn match ctStringEscape  "\%(\\M-\\C-\|\\C-\\M-\|\\M-\\c\|\\c\\M-\|\\c\|\\C-\|\\M-\)\%(\\\o\{1,3}\|\\x\x\{1,2}\|\\\=\S\)" contained display

" Quantifiers
syn match ctQuantifier "+" contained display
syn match ctQuantifier "?" contained display
syn match ctQuantifier "\d*\*\d*" contained display

" Operators
syn match ctOperator "|" contained

" Extensions
syn region ctRubyBlock start="{"ms=e+1 end="}"me=s-1 contains=@rubyTop contained
syn match ctTag "<\s*\(\(::\)\?\u\w*\)\+\s*>" contains=ctModule contained

" Declarations
syn match ctRequire "\<require\>" nextgroup=ctString skipwhite skipnl
syn match ctGrammar "\<grammar\>" nextgroup=ctModule skipwhite skipnl
syn match ctInclude "\<include\>" nextgroup=ctModule skipwhite skipnl contained
syn match ctRoot    "\<root\>"    nextgroup=ctVariable skipwhite skipnl contained
syn match ctRule    "\<rule\>"    nextgroup=ctVariable skipwhite skipnl contained

" Blocks
syn region ctGrammarBlock start="\<grammar\>" matchgroup=ctGrammar end="\<end\>" contains=ctComment,ctGrammar,ctInclude,ctRoot,ctRuleBlock fold
syn region ctRuleBlock start="\<rule\>" matchgroup=ctRule end="\<end\>" contains=ALLBUT,ctRequire,ctGrammar,ctInclude,ctRoot fold

" Groups
hi def link ctComment       Comment

hi def link ctRequire       Include
hi def link ctInclude       Include
hi def link ctGrammar       ctDefine
hi def link ctRoot          ctDefine
hi def link ctRule          ctDefine
hi def link ctDefine        Define

hi def link ctConstant      Type
hi def link ctVariable      Function
hi def link ctKeyword       Keyword

hi def link ctString          ctTerminal
hi def link ctCharacterClass  ctTerminal
hi def link ctAnything        ctTerminal
hi def link ctRegexp          ctTerminal
hi def link ctTerminal        String

hi def link ctRegexpDelimiter ctStringDelimiter
hi def link ctStringDelimiter Delimiter

hi def link ctStringEscape  Special

hi def link ctQuantifier    ctOperator
hi def link ctOperator      Operator

let b:current_syntax = "citrus"
