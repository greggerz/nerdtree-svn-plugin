# nerdtree-svn-plugin
===================

A plugin of NERDTree showing svn status flags.

## Installation

For Pathogen

`git clone https://github.com/greggerz/nerdtree-svn-plugin.git ~/.vim/bundle/nerdtree-svn-plugin`

Reload `vim`

For Vundle

`Plugin 'scrooloose/nerdtree'`

`Plugin 'greggerz/nerdtree-svn-plugin'`

For NeoBundle

`NeoBundle 'scrooloose/nerdtree'`

`NeoBundle 'greggerz/nerdtree-svn-plugin'`

For Plug

`Plug 'scrooloose/nerdtree'`

`Plug 'greggerz/nerdtree-svn-plugin'`

## Limitations

* Currently the plugin only works with the first column of the status output

## FAQ

* How do I customize the symbols?
	```vimscript
	let g:NERDTreeSvnIndicatorMapCustom = {
        \ 'Modified'  : '✹',
        \ 'Addition'  : '✚',
        \ 'Untracked' : '✭',
        \ 'Replaced'  : '➜',
        \ 'Deleted'   : '✖',
        \ 'Dirty'     : '✗',
        \ 'Clean'     : '✔︎',
        \ 'Ignored'   : '☒',
        \ 'Missing'   : '⁈',
        \ 'Conflict'  : '⇏',
        \ 'Externals' : '↰',
        \ 'Unknown'   : '?'
	    \ }
	 ```
* How do I get the `Ignored` status to show?
    ```vimscript
    let g:NERDTreeShowIgnoredStatus = 1
    ```

## Credits
*  [scrooloose](https://github.com/scrooloose): Creating NERDTree
*  [Xuyuanp](https://github.com/Xuyuanp): Creating nerdtree-git-plugin
*  All contributors to NERDTree and nerdtree-git-plugin
