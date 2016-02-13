let s:V = protocol#vital()
let s:File = s:V.import('System.File')
let s:Path = s:V.import('System.Filepath')
let s:Guard = s:V.import('Vim.Guard')
let s:Buffer = s:V.import('Vim.Buffer')
let s:Process = s:V.import('Vim.Process')

function! s:throw(msg) abort
  call protocol#throw(printf('zip: %s', a:msg))
endfunction
function! s:zip(args, ...) abort
  let options = get(a:000, 0, {})
  if !executable(g:protocol#zip#zip_exec)
    call s:throw(printf(
          \ '"%s" is not executable. Assign zip executable to g:protocol#zip#zip_exec.',
          \ g:protocol#zip#zip_exec,
          \))
  endif
  let args = [g:protocol#zip#zip_exec] + a:args
  let result = s:Process.system(args, options)
  if s:Process.get_last_status()
    call s:throw(printf(
          \ 'Fail: %s%s',
          \ join(args, ' '),
          \ empty(result) ? '' : "\n" . result,
          \))
  endif
  return protocol#split_posix_text(result)
endfunction
function! s:unzip(args, ...) abort
  let options = get(a:000, 0, {})
  if !executable(g:protocol#zip#unzip_exec)
    call s:throw(printf(
          \ '"%s" is not executable. Assign unzip executable to g:protocol#zip#unzip_exec.',
          \ g:protocol#zip#unzip_exec,
          \))
  endif
  let args = [g:protocol#zip#unzip_exec] + a:args
  let result = s:Process.system(args, options)
  if s:Process.get_last_status()
    call s:throw(printf(
          \ 'Fail: %s%s',
          \ join(args, ' '),
          \ empty(result) ? '' : "\n" . result,
          \))
  endif
  return protocol#split_posix_text(result)
endfunction
function! s:split_uri(uri) abort
  return matchlist(
        \ a:uri,
        \ '^zip://\(.*\):\(.\{-}\)$'
        \)[1 : 2]
endfunction
function! s:get_cache_filename(uri) abort
  let filename = fnameescape(a:uri)
  let filename = substitute(filename, '[:\/]', '+', 'g')
  return filename
endfunction
function! s:get_local_filename(zipfile) abort
  if a:zipfile !~# '^\a\+://'
    return a:zipfile
  endif
  let zipfile = s:Path.join(
        \ expand(g:protocol#zip#cache_directory),
        \ s:get_cache_filename(a:zipfile),
        \)
  if !isdirectory(fnamemodify(zipfile, ':h'))
    call mkdir(fnamemodify(zipfile, ':h'), 'p')
  endif
  if !filereadable(zipfile)
    let content = protocol#read_content(a:zipfile)
    call writefile(content, zipfile)
  endif
  return zipfile
endfunction

function! protocol#zip#read(uri, ...) abort
  let [zipfile, filename] = s:split_uri(a:uri)
  let local_zipfile = s:get_local_filename(zipfile)
  return s:unzip(['-p', '--', local_zipfile, filename])
endfunction
function! protocol#zip#write(uri, content, ...) abort
  let [zipfile, filename] = s:split_uri(a:uri)
  if !protocol#zip#is_writable(zipfile)
    call s:throw(printf(
          \ 'A zip file %s is not writable',
          \ zipfile,
          \))
  endif
  let local_zipfile = fnamemodify(s:get_local_filename(zipfile), ':p')
  let cwd = getcwd()
  let tempdir = tempname()
  try
    call mkdir(tempdir, 'p')
    execute printf('cd %s', fnameescape(tempdir))
    call mkdir(fnamemodify(filename, ':h'), 'p')
    call writefile(a:content, filename)
    call s:zip(['-u', local_zipfile, filename])
    if zipfile =~# '^\a\+://'
      call protocol#write_content(zipfile, readfile(local_zipfile))
    endif
  finally
    execute printf('cd %s', fnameescape(cwd))
    call s:File.rmdir(tempdir, 'r')
  endtry
endfunction
function! protocol#zip#is_writable(uri) abort
  return 1
endfunction

function! protocol#zip#SourceCmd(uri, ...) abort
  let cmdarg  = get(a:000, 0, v:cmdarg)
  let options = protocol#parse_cmdarg(cmdarg)
  let content = protocol#zip#read(a:uri)
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
function! protocol#zip#FileReadCmd(uri, ...) abort
  call protocol#doautocmd('FileReadPre')
  if get(b:, '_protocol_cancel', '') !~# '^\%(zip\)\?$'
    return
  endif
  let options = get(a:000, 0, {})
  let content = protocol#zip#read(a:uri)
  call s:Buffer.read_content(content, options)
  call protocol#doautocmd('FileReadPost')
endfunction
function! protocol#zip#BufReadCmd(uri, ...) abort
  call protocol#doautocmd('BufReadPre')
  if get(b:, '_protocol_cancel', '') !~# '^\%(zip\)\?$'
    return
  endif
  let options = get(a:000, 0, {})
  let content = protocol#zip#read(a:uri)
  call s:Buffer.edit_content(content, options)
  setlocal noswapfile buftype=acwrite
  augroup vim_protocol_internal_zip_BufReadCmd
    autocmd! * <buffer>
    autocmd BufWriteCmd <buffer> call protocol#zip#BufWriteCmd(expand('<afile>'))
  augroup END
  call protocol#doautocmd('BufReadPost')
endfunction
function! protocol#zip#BufWriteCmd(uri, ...) abort
  call protocol#doautocmd('BufWritePre')
  if get(b:, '_protocol_cancel', '') !~# '^\%(zip\)\?$'
    return
  endif
  let options = get(a:000, 0, {})
  let guard = s:Guard.store('&binary')
  try
    set binary
    let content = getline(1, '$')
    call protocol#zip#write(a:uri, content)
    setlocal nomodified
  finally
    call guard.restore()
  endtry
  call protocol#doautocmd('BufWritePost')
endfunction

function! s:open(zipfile, filename, ...) abort
  let options = get(a:000, 0, {})
  let bufname = printf('zip://%s:%s', a:zipfile, a:filename)
  let guard = s:Guard.store('&eventignore')
  try
    set eventignore+=BufReadCmd
    call s:Buffer.open(bufname, 'edit')
    call protocol#zip#BufReadCmd(bufname, options)
  catch /^protocol:/
    call protocol#handle_exception()
  finally
    call guard.restore()
  endtry
endfunction
function! protocol#zip#browse(zipfile, ...) abort
  let options = get(a:000, 0, {})
  let zipfile = s:get_local_filename(a:zipfile)
  let content = s:unzip(['-Z', '-1', '--', zipfile])
  let content = filter(content, 'v:val !~# "/$"')
  let content = extend([
        \ printf('%s | Hit <Return> to open a file under the cursor', a:zipfile),
        \], content)
  call s:Buffer.edit_content(content, options)
  setlocal nomodifiable
  setlocal noswapfile nobuflisted nowrap
  setlocal buftype=nofile bufhidden=hide
  setlocal filetype=protocol-zip
  augroup vim_protocol_internal_zip_browse
    autocmd! * <buffer>
    autocmd BufReadCmd <buffer> call protocol#zip#browse(b:_protocol_zip_filename)
  augroup END
  nnoremap <silent><buffer> <Plug>(protocol-zip-open)
        \ :<C-u>call <SID>open(expand('%'), getline('.'))<CR>
  nmap <buffer> <CR> <Plug>(protocol-zip-open)
endfunction
function! protocol#zip#define_highlight() abort
  highlight default link ProtocolZipComment Comment
endfunction
function! protocol#zip#define_syntax() abort
  syntax match ProtocolZipComment /\%^.*$/
endfunction

augroup vim_protocol_internal_zip_pseudo
  autocmd! *
  autocmd FileReadPre  zip://* :
  autocmd FileReadPost zip://* :
  autocmd BufReadPre   zip://* :
  autocmd BufReadPost  zip://* :
  autocmd BufWritePre  zip://* :
  autocmd BufWritePost zip://* :
augroup END

call protocol#define_variables('zip', {
      \ 'zip_exec': 'zip',
      \ 'unzip_exec': 'unzip',
      \ 'cache_directory': '~/.cache/vim-protocol/zip',
      \})
