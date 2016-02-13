let s:V = vital#of('vim_protocol')
let s:Prompt = s:V.import('Vim.Prompt')

function! protocol#vital() abort
  return s:V
endfunction

function! protocol#throw(msg) abort
  throw printf('protocol: %s', a:msg)
endfunction

function! protocol#parse_cmdarg(cmdarg) abort
  let options = {}
  if a:cmdarg =~# '++enc='
    let options.encoding = matchstr(a:cmdarg, '++enc=\zs[^ ]\+\ze')
  endif
  if a:cmdarg =~# '++ff='
    let options.fileformat = matchstr(a:cmdarg, '++ff=\zs[^ ]\+\ze')
  endif
  if a:cmdarg =~# '++bad='
    let options.bad = matchstr(a:cmdarg, '++bad=\zs[^ ]\+\ze')
  endif
  let options.binary   = a:cmdarg =~# '++bin'
  let options.nobinary = a:cmdarg =~# '++nobin'
  let options.edit     = a:cmdarg =~# '++edit'
  return options
endfunction

function! protocol#split_posix_text(text, ...) abort
  " NOTE:
  " A definition of a TEXT file is "A file that contains characters organized
  " into one or more lines."
  " A definition of a LINE is "A sequence of zero ore more non- <newline>s
  " plus a terminating <newline>"
  " TEXT into List; split({text}, '\r\?\n', 1); add an extra empty line at the
  " end of List because the end of TEXT ends with <newline> and keepempty=1 is
  " specified. (btw. keepempty=0 cannot be used because it will remove
  " emptylines in head and tail).
  " That's why remove a trailing <newline> before proceeding to 'split'
  " REF:
  " http://pubs.opengroup.org/onlinepubs/000095399/basedefs/xbd_chap03.html#tag_03_392
  " http://pubs.opengroup.org/onlinepubs/000095399/basedefs/xbd_chap03.html#tag_03_205
  let newline = get(a:000, 0, '\r\?\n')
  let text = substitute(a:text, newline . '$', '', '')
  return split(text, newline, 1)
endfunction

function! protocol#doautocmd(name, ...) abort
  let pattern = get(a:000, 0, '')
  let expr = empty(pattern)
        \ ? '#' . a:name
        \ : '#' . a:name . '#' . pattern
  let eis = split(&eventignore, ',')
  if index(eis, a:name) >= 0 || index(eis, 'all') >= 0 || !exists(expr)
    " the specified event is ignored or not exists
    return
  endif
  let nomodeline = has('patch-7.4.438') && a:name ==# 'User'
        \ ? '<nomodeline> '
        \ : ''
  execute printf('doautocmd %s%s %s', nomodeline, a:name, pattern)
endfunction

function! protocol#define_variables(prefix, defaults) abort
  " Note:
  "   Funcref is not supported while the variable must start with a capital
  let prefix = empty(a:prefix)
        \ ? 'g:protocol'
        \ : printf('g:protocol#%s', a:prefix)
  for [key, value] in items(a:defaults)
    let name = printf('%s#%s', prefix, key)
    if !exists(name)
      execute printf('let %s = %s', name, string(value))
    endif
    unlet value
  endfor
endfunction

function! protocol#read_content(filename) abort
  if a:filename !~# '^\a\+://'
    return readfile(a:filename)
  endif
  let protocol = matchstr(a:filename, '^\a\+\ze://')
  let fname = printf('protocol#%s#read', protocol)
  try
    return call(fname, [a:filename])
  catch /^protocol:/
    call protocol#handle_exception()
  endtry
endfunction

function! protocol#write_content(filename, content) abort
  if a:filename !~# '^\a\+://'
    return readfile(a:filename)
  endif
  let protocol = matchstr(a:filename, '^\a\+\ze://')
  let fname = printf('protocol#%s#write', protocol)
  try
    return call(fname, [a:filename, a:content])
  catch /^protocol:/
    call protocol#handle_exception()
  endtry
endfunction

function! protocol#is_writable(filename) abort
  if a:filename !~# '^\a\+://'
    return filewritable(a:filename)
  endif
  let protocol = matchstr(a:filename, '^\a\+\ze://')
  let fname = printf('protocol#%s#is_writable', protocol)
  try
    return call(fname, [a:filename])
  catch /^protocol:/
    call protocol#handle_exception()
  endtry
endfunction

function! protocol#handle_autocmd(protocol, name) abort
  let fname = printf('protocol#%s#%s', a:protocol, a:name)
  try
    call call(fname, [expand('<afile>')])
  catch /^protocol:/
    call protocol#handle_exception()
  endtry
endfunction

function! protocol#handle_exception() abort
  call s:Prompt.error(v:exception)
  call s:Prompt.debug(v:throwpoint)
endfunction
