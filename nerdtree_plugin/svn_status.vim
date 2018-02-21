if exists('g:loaded_nerdtree_svn_status')
    finish
endif
let g:loaded_nerdtree_svn_status = 1

if !exists('g:NERDTreeShowSvnStatus')
    let g:NERDTreeShowSvnStatus = 1
endif

if g:NERDTreeShowSvnStatus == 0
    finish
endif

if !exists('g:NERDTreeMapNextHunk')
    let g:NERDTreeMapNextHunk = ']c'
endif

if !exists('g:NERDTreeMapPrevHunk')
    let g:NERDTreeMapPrevHunk = '[c'
endif

if !exists('g:NERDTreeUpdateOnWrite')
    let g:NERDTreeUpdateOnWrite = 1
endif

if !exists('g:NERDTreeUpdateOnCursorHold')
    let g:NERDTreeUpdateOnCursorHold = 1
endif

if !exists('s:NERDTreeSvnIndicatorMapCustom')
    let s:NERDTreeSvnIndicatorMapCustom = {
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
endif


function! NERDTreeSvnStatusRefreshListener(event)
    if !exists('b:NOT_A_SVN_REPOSITORY')
        call g:NERDTreeSvnStatusRefresh()
    endif
    let l:path = a:event.subject
    let l:flag = g:NERDTreeGetSvnStatusPrefix(l:path)
    call l:path.flagSet.clearFlags('svn')
    if l:flag !=# ''
        call l:path.flagSet.addFlag('svn', l:flag)
    endif
endfunction

" FUNCTION: g:NERDTreeSvnStatusRefresh() {{{2
" refresh cached svn status
function! g:NERDTreeSvnStatusRefresh()
    let b:NERDTreeCachedSvnFileStatus = {}
    let b:NERDTreeCachedSvnDirtyDir   = {}
    let b:NOT_A_SVN_REPOSITORY        = 1

    let l:root = b:NERDTree.root.path.str()
    let l:svncmd = 'svn status'
    if g:NERDTreeShowIgnoredStatus
        let l:svncmd = l:svncmd . ' --no-ignore'
    endif
    if exists('g:NERDTreeSvnStatusIgnoreSubmodules')
        let l:svncmd = l:svncmd . ' --ignore-externals'
        if g:NERDTreeSvnStatusIgnoreSubmodules ==# 'all' || g:NERDTreeSvnStatusIgnoreSubmodules ==# 'dirty' || g:NERDTreeSvnStatusIgnoreSubmodules ==# 'untracked'
            let l:svncmd = l:svncmd . '=' . g:NERDTreeSvnStatusIgnoreSubmodules
        endif
    endif
    let l:statusesStr = system(l:svncmd)
    let l:statusesSplit = split(l:statusesStr, '\n')
    if l:statusesSplit != [] && l:statusesSplit[0] =~# 'fatal:.*'
        let l:statusesSplit = []
        return
    endif
    let b:NOT_A_SVN_REPOSITORY = 0

    for l:statusLine in l:statusesSplit
        " cache svn status of files
        let l:pathStr = substitute(l:statusLine, '...', '', '')
        let l:pathSplit = split(l:pathStr, ' -> ')
        if len(l:pathSplit) == 2
            call s:NERDTreeCacheDirtyDir(l:pathSplit[0])
            let l:pathStr = l:pathSplit[1]
        else
            let l:pathStr = substitute(l:pathSplit[0], '     ', '', '')
        endif
        let l:pathStr = s:NERDTreeTrimDoubleQuotes(l:pathStr)
        if l:pathStr =~# '\.\./.*'
            continue
        endif
        let l:statusKey = s:NERDTreeGetFileSvnStatusKey(l:statusLine[0])
        let b:NERDTreeCachedSvnFileStatus[fnameescape(l:pathStr)] = l:statusKey

        if l:statusKey == 'Ignored'
            if isdirectory(l:pathStr)
                let b:NERDTreeCachedSvnDirtyDir[fnameescape(l:pathStr)] = l:statusKey
            endif
        else
            call s:NERDTreeCacheDirtyDir(l:pathStr)
        endif
    endfor
endfunction

function! s:NERDTreeCacheDirtyDir(pathStr)
    " cache dirty dir
    let l:dirtyPath = s:NERDTreeTrimDoubleQuotes(a:pathStr)
    if l:dirtyPath =~# '\.\./.*'
        return
    endif
    let l:dirtyPath = substitute(l:dirtyPath, '/[^/]*$', '/', '')
    while l:dirtyPath =~# '.\+/.*' && has_key(b:NERDTreeCachedSvnDirtyDir, fnameescape(l:dirtyPath)) == 0
        let b:NERDTreeCachedSvnDirtyDir[fnameescape(l:dirtyPath)] = 'Dirty'
        let l:dirtyPath = substitute(l:dirtyPath, '/[^/]*/$', '/', '')
    endwhile
endfunction

function! s:NERDTreeTrimDoubleQuotes(pathStr)
    let l:toReturn = substitute(a:pathStr, '^"', '', '')
    let l:toReturn = substitute(l:toReturn, '"$', '', '')
    return l:toReturn
endfunction

" FUNCTION: g:NERDTreeGetSvnStatusPrefix(path) {{{2
" return the indicator of the path
" Args: path
let s:SvnStatusCacheTimeExpiry = 2
let s:SvnStatusCacheTime = 0
function! g:NERDTreeGetSvnStatusPrefix(path)
    if localtime() - s:SvnStatusCacheTime > s:SvnStatusCacheTimeExpiry
        let s:SvnStatusCacheTime = localtime()
        call g:NERDTreeSvnStatusRefresh()
    endif
    let l:pathStr = a:path.str()
    let l:cwd = b:NERDTree.root.path.str() . a:path.Slash()
    if nerdtree#runningWindows()
        let l:pathStr = a:path.WinToUnixPath(l:pathStr)
        let l:cwd = a:path.WinToUnixPath(l:cwd)
    endif
    let l:pathStr = substitute(l:pathStr, fnameescape(l:cwd), '', '')
    let l:statusKey = ''
    if a:path.isDirectory
        let l:statusKey = get(b:NERDTreeCachedSvnDirtyDir, fnameescape(l:pathStr . '/'), '')
    else
        let l:statusKey = get(b:NERDTreeCachedSvnFileStatus, fnameescape(l:pathStr), '')
    endif
    return s:NERDTreeGetIndicator(l:statusKey)
endfunction

" FUNCTION: s:NERDTreeGetCWDSvnStatus() {{{2
" return the indicator of cwd
function! g:NERDTreeGetCWDSvnStatus()
    if b:NOT_A_SVN_REPOSITORY
        return ''
    elseif b:NERDTreeCachedSvnDirtyDir == {} && b:NERDTreeCachedSvnFileStatus == {}
        return s:NERDTreeGetIndicator('Clean')
    endif
    return s:NERDTreeGetIndicator('Dirty')
endfunction

function! s:NERDTreeGetIndicator(statusKey)
    if exists('g:NERDTreeIndicatorMapCustom')
        let l:indicator = get(g:NERDTreeIndicatorMapCustom, a:statusKey, '')
        if l:indicator !=# ''
            return l:indicator
        endif
    endif
    let l:indicator = get(s:NERDTreeSvnIndicatorMapCustom, a:statusKey, '')
    if l:indicator !=# ''
        return l:indicator
    endif
    return ''
endfunction

function! s:NERDTreeGetFileSvnStatusKey(us)
    if a:us ==# 'A'
        return 'Addition'
    elseif a:us ==# '?'
        return 'Untracked'
    elseif a:us ==# 'M'
        return 'Modified'
    elseif a:us ==# 'R'
        return 'Replaced'
    elseif a:us ==# 'D'
        return 'Deleted'
    elseif a:us ==# 'I'
        return 'Ignored'
    elseif a:us ==# '!'
        return 'Missing'
    elseif a:us ==# 'C'
        return 'Conflict'
    elseif a:us ==# 'X'
        return 'Externals'
    else
        return 'Unknown'
    endif
endfunction

" FUNCTION: s:jumpToNextHunk(node) {{{2
function! s:jumpToNextHunk(node)
    let l:position = search('\[[^{RO}].*\]', '')
    if l:position
        call nerdtree#echo('Jump to next hunk ')
    endif
endfunction

" FUNCTION: s:jumpToPrevHunk(node) {{{2
function! s:jumpToPrevHunk(node)
    let l:position = search('\[[^{RO}].*\]', 'b')
    if l:position
        call nerdtree#echo('Jump to prev hunk ')
    endif
endfunction

" Function: s:SID()   {{{2
function s:SID()
    if !exists('s:sid')
        let s:sid = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
    endif
    return s:sid
endfun

" FUNCTION: s:NERDTreeSvnStatusKeyMapping {{{2
function! s:NERDTreeSvnStatusKeyMapping()
    let l:s = '<SNR>' . s:SID() . '_'

    call NERDTreeAddKeyMap({
        \ 'key': g:NERDTreeMapNextHunk,
        \ 'scope': 'Node',
        \ 'callback': l:s.'jumpToNextHunk',
        \ 'quickhelpText': 'Jump to next svn hunk' })

    call NERDTreeAddKeyMap({
        \ 'key': g:NERDTreeMapPrevHunk,
        \ 'scope': 'Node',
        \ 'callback': l:s.'jumpToPrevHunk',
        \ 'quickhelpText': 'Jump to prev svn hunk' })

endfunction

augroup nerdtreesvnplugin
    autocmd CursorHold * silent! call s:CursorHoldUpdate()
augroup END
" FUNCTION: s:CursorHoldUpdate() {{{2
function! s:CursorHoldUpdate()
    if g:NERDTreeUpdateOnCursorHold != 1
        return
    endif

    if !g:NERDTree.IsOpen()
        return
    endif

    " Do not update when a special buffer is selected
    if !empty(&l:buftype)
        return
    endif

    let l:winnr = winnr()
    let l:altwinnr = winnr('#')

    call g:NERDTree.CursorToTreeWin()
    call b:NERDTree.root.refreshFlags()
    call NERDTreeRender()

    exec l:altwinnr . 'wincmd w'
    exec l:winnr . 'wincmd w'
endfunction

augroup nerdtreesvnplugin
    autocmd BufWritePost * call s:FileUpdate(expand('%:p'))
augroup END
" FUNCTION: s:FileUpdate(fname) {{{2
function! s:FileUpdate(fname)
    if g:NERDTreeUpdateOnWrite != 1
        return
    endif

    if !g:NERDTree.IsOpen()
        return
    endif

    let l:winnr = winnr()
    let l:altwinnr = winnr('#')

    call g:NERDTree.CursorToTreeWin()
    let l:node = b:NERDTree.root.findNode(g:NERDTreePath.New(a:fname))
    if l:node == {}
        return
    endif
    call l:node.refreshFlags()
    let l:node = l:node.parent
    while !empty(l:node)
        call l:node.refreshDirFlags()
        let l:node = l:node.parent
    endwhile

    call NERDTreeRender()

    exec l:altwinnr . 'wincmd w'
    exec l:winnr . 'wincmd w'
endfunction

augroup AddHighlighting
    autocmd FileType nerdtree call s:AddHighlighting()
augroup END
function! s:AddHighlighting()
    let l:synmap = {
                \ 'NERDTreeSvnStatusModified'    : s:NERDTreeGetIndicator('Modified'),
                \ 'NERDTreeSvnStatusStaged'      : s:NERDTreeGetIndicator('Addition'),
                \ 'NERDTreeSvnStatusUntracked'   : s:NERDTreeGetIndicator('Untracked'),
                \ 'NERDTreeSvnStatusRenamed'     : s:NERDTreeGetIndicator('Replaced'),
                \ 'NERDTreeSvnStatusIgnored'     : s:NERDTreeGetIndicator('Ignored'),
                \ 'NERDTreeSvnStatusDirDirty'    : s:NERDTreeGetIndicator('Dirty'),
                \ 'NERDTreeSvnStatusDirClean'    : s:NERDTreeGetIndicator('Clean')
                \ }

    for l:name in keys(l:synmap)
        exec 'syn match ' . l:name . ' #' . escape(l:synmap[l:name], '~') . '# containedin=NERDTreeFlags'
    endfor

    hi def link NERDTreeSvnStatusModified Special
    hi def link NERDTreeSvnStatusStaged Function
    hi def link NERDTreeSvnStatusRenamed Title
    hi def link NERDTreeSvnStatusUnmerged Label
    hi def link NERDTreeSvnStatusUntracked Comment
    hi def link NERDTreeSvnStatusDirDirty Tag
    hi def link NERDTreeSvnStatusDirClean DiffAdd
    " TODO: use diff color
    hi def link NERDTreeSvnStatusIgnored DiffAdd
endfunction

function! s:SetupListeners()
    call g:NERDTreePathNotifier.AddListener('init', 'NERDTreeSvnStatusRefreshListener')
    call g:NERDTreePathNotifier.AddListener('refresh', 'NERDTreeSvnStatusRefreshListener')
    call g:NERDTreePathNotifier.AddListener('refreshFlags', 'NERDTreeSvnStatusRefreshListener')
endfunction

if g:NERDTreeShowSvnStatus && executable('svn')
    call s:NERDTreeSvnStatusKeyMapping()
    call s:SetupListeners()
endif
