let s:V = protocol#vital()
let s:HTTP = s:V.import('Web.HTTP')
let s:Buffer = s:V.import('Vim.Buffer')

function! protocol#http#get(url) abort
  redraw | echo 'Requesting content on ' . a:url . ' ...'
  let response = s:HTTP.get(a:url)
  redraw | echo
  if !response.success
    let msg = printf('%s %s: %s',
          \ response.status,
          \ response.statusText,
          \ response.content
          \)
    call protocol#throw(msg)
  endif
  return protocol#split_posix_text(response.content)
endfunction

function! protocol#http#source(url, ...) abort
  let cmdarg  = get(a:000, 0, v:cmdarg)
  let options = protocol#parse_cmdarg(cmdarg)
  let content = protocol#http#get(a:url)
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

function! protocol#http#read(url, ...) abort
  call protocol#doautocmd('FileReadPre')
  let cmdarg  = get(a:000, 0, v:cmdarg)
  let options = protocol#parse_cmdarg(cmdarg)
  let content = protocol#http#get(a:url)
  call s:Buffer.read_content(content, options)
  call protocol#doautocmd('FileReadPost')
endfunction

function! protocol#http#edit(url, ...) abort
  call protocol#doautocmd('BufReadPre')
  let cmdarg  = get(a:000, 0, v:cmdarg)
  let options = protocol#parse_cmdarg(cmdarg)
  let content = protocol#http#get(a:url)
  call s:Buffer.edit_content(content, options)
  setlocal readonly noswapfile buftype=nowrite
  call protocol#doautocmd('BufReadPost')
endfunction
