let s:V = protocol#vital()
let s:HTTP = s:V.import('Web.HTTP')
let s:Buffer = s:V.import('Vim.Buffer')

function! s:throw(msg) abort
  call protocol#throw(printf('http: %s', a:msg))
endfunction
function! protocol#http#read(uri, ...) abort
  let tempfile = resolve(tempname())
  try
    let response = s:HTTP.request({
          \ 'method': 'GET',
          \ 'url': a:uri,
          \ 'outputFile': tempfile,
          \})
    let content  = readfile(tempfile)
    if !response.success
      let msg = printf('%s %s: %s',
            \ response.status,
            \ response.statusText,
            \ join(content, "\n"),
            \)
      call s:throw(msg)
    endif
    return content
  finally
    if filereadable(tempfile)
      call delete(tempfile)
    endif
  endtry
endfunction
function! protocol#http#write(uri, content, ...) abort
  call s:throw('http protocol does not support writing content')
endfunction
function! protocol#http#is_writable(uri) abort
  return 0
endfunction

function! protocol#http#SourceCmd(uri, ...) abort
  let cmdarg  = get(a:000, 0, v:cmdarg)
  let options = protocol#parse_cmdarg(cmdarg)
  let content = protocol#http#read(a:uri)
  try
    let tempfile = tempname()
    call writefile(content, tempfile)
    execute printf('source %s', fnameescape(tempfile))
  finally
    if filereadable(tempfile)
      call delete(tempfile)
    endif
  endtry
endfunction

function! protocol#http#FileReadCmd(uri, ...) abort
  call protocol#doautocmd('FileReadPre')
  if get(b:, '_protocol_cancel', '') !~# '^\%(http\)\?$'
    return
  endif
  let cmdarg  = get(a:000, 0, v:cmdarg)
  let options = protocol#parse_cmdarg(cmdarg)
  let content = protocol#http#read(a:uri)
  call s:Buffer.read_content(content, options)
  call protocol#doautocmd('FileReadPost')
endfunction

function! protocol#http#BufReadCmd(uri, ...) abort
  call protocol#doautocmd('BufReadPre')
  if get(b:, '_protocol_cancel', '') !~# '^\%(http\)\?$'
    return
  endif
  let cmdarg  = get(a:000, 0, v:cmdarg)
  let options = protocol#parse_cmdarg(cmdarg)
  let content = protocol#http#read(a:uri)
  call s:Buffer.edit_content(content, options)
  setlocal readonly noswapfile buftype=nowrite
  call protocol#doautocmd('BufReadPost')
endfunction

augroup vim_protocol_internal_http_pseudo
  autocmd! *
  autocmd FileReadPre http://* :
  autocmd FileReadPre https://* :
  autocmd FileReadPost http://* :
  autocmd FileReadPost https://* :
  autocmd BufReadPre http://* :
  autocmd BufReadPre https://* :
  autocmd BufReadPost http://* :
  autocmd BufReadPost https://* :
augroup END
