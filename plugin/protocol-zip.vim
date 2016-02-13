if !get(g:, 'protocol_enable_zip', 1)
  finish
endif

augroup vim_protocol_internal_zip
  autocmd! *
  autocmd BufReadCmd  zip://*  nested call protocol#handle_autocmd('zip', 'BufReadCmd')
  autocmd FileReadCmd zip://*  nested call protocol#handle_autocmd('zip', 'FileReadCmd')
  autocmd SourceCmd   zip://*  nested call protocol#handle_autocmd('zip', 'SourceCmd')

  autocmd BufReadCmd  *.zip    nested call protocol#handle_autocmd('zip', 'browse')
  autocmd BufReadPre  *.zip    let b:_protocol_cancel = 'zip'
augroup END

