augroup vim_protocol_internal
  autocmd! *
  autocmd BufReadCmd  ftp://* nested call protocol#handle_autocmd('http', 'edit')
  autocmd BufReadCmd  http://* nested call protocol#handle_autocmd('http', 'edit')
  autocmd BufReadCmd  https://* nested call protocol#handle_autocmd('http', 'edit')
  autocmd FileReadCmd ftp://* nested call protocol#handle_autocmd('http', 'read')
  autocmd FileReadCmd http://* nested call protocol#handle_autocmd('http', 'read')
  autocmd FileReadCmd https://* nested call protocol#handle_autocmd('http', 'read')
  try
    autocmd SourceCmd ftp://* nested call protocol#handle_autocmd('http', 'source')
    autocmd SourceCmd http://* nested call protocol#handle_autocmd('http', 'source')
    autocmd SourceCmd https://* nested call protocol#handle_autocmd('http', 'source')
  catch /-Vim\%((\a\+)\)\=E216/
    autocmd SourcePre ftp://* nested call protocol#handle_autocmd('http', 'source')
    autocmd SourcePre http://* nested call protocol#handle_autocmd('http', 'source')
    autocmd SourcePre https://* nested call protocol#handle_autocmd('http', 'source')
  endtry
augroup END
