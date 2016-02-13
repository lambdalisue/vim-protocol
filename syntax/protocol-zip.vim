if exists('b:current_syntax')
  finish
endif
let b:current_syntax = 'protocol-zip'

syntax clear
call protocol#zip#define_highlight()
call protocol#zip#define_syntax()
