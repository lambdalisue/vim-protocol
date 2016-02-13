vim-protocol
===============================================================================
![Version 0.1.0](https://img.shields.io/badge/version-0.1.0-yellow.svg?style=flat-square) ![Support Vim 7.3 or above](https://img.shields.io/badge/support-Vim%207.3%20or%20above-yellowgreen.svg?style=flat-square) [![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE) [![Doc](https://img.shields.io/badge/doc-%3Ah%20protocol-orange.svg?style=flat-square)](doc/protocol.txt)

Provide features to open, read, source remote contents of http:// or https:// without using `netrw.vim`.
Designed for user who don't use most of features of `netrw.vim` but want to access remote contents.

Attention
-------------------------------------------------------------------------------

**This plugin conflicts with `netrw.vim`**, Vim's default plugin, so you need to disable the plugin.
If you need features of `netrw.vim`, simply don't use this plugin.

Install
-------------------------------------------------------------------------------
Use [Plug.vim][], [neobundle.vim][], or whatever like:

```vim
" Plug.vim
Plug 'lambdalisue/vim-protocol'

" neobundle.vim
NeoBundle 'lambdalisue/vim-protocol'

" neobundle.vim (Lazy)
NeoBundleLazy 'lambdalisue/vim-protocol', {
      \ 'on_path': '^https\?://',
      \}
```

Or copy the repository into one of your `runtimepath` of Vim.

[Plug.vim]: https://github.com/junequnn/vim-plug
[neobundle.vim]: https://github.com/Shougo/neobundle.vim

After you install the plugin, you **must** disable `netrw.vim` to prevent conflict features.
You can disable `netrw.vim` with the following line in your `.vimrc`

```vim
" disable netrw.vim
let g:loaded_netrw             = 1
let g:loaded_netrwPlugin       = 1
let g:loaded_netrwSettings     = 1
let g:loaded_netrwFileHandlers = 1
```

Usage
-------------------------------------------------------------------------------

This plugin provides `BufReadCmd`, `FileReadCmd` and `SourceCmd` for filenames starts with `http://` or `https://`.
In short, the following command request remote contents of corresponding URLs.

```vim
:edit https://raw.githubusercontent.com/lambdalisue/rook/master/home/.vim/vimrc
" Read a remote content and open a corresponding buffer
:read https://raw.githubusercontent.com/lambdalisue/rook/master/home/.vim/vimrc
" Read a remote content and insert into the current buffer
:source https://raw.githubusercontent.com/lambdalisue/rook/master/home/.vim/vimrc
" Read a remote content and source the content as Vim script
```

License
-------------------------------------------------------------------------------
The MIT License (MIT)

Copyright (c) 2016 Alisue, hashnote.net

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
