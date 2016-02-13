if !get(g:, 'protocol_enable_http', 1)
  finish
endif

augroup vim_protocol_internal_http
  autocmd! *
  autocmd BufReadCmd  http://*  nested call protocol#handle_autocmd('http', 'BufReadCmd')
  autocmd BufReadCmd  https://* nested call protocol#handle_autocmd('http', 'BufReadCmd')
  autocmd FileReadCmd http://*  nested call protocol#handle_autocmd('http', 'FileReadCmd')
  autocmd FileReadCmd https://* nested call protocol#handle_autocmd('http', 'FileReadCmd')
  autocmd SourceCmd   http://*  nested call protocol#handle_autocmd('http', 'SourceCmd')
  autocmd SourceCmd   https://* nested call protocol#handle_autocmd('http', 'SourceCmd')
augroup END
