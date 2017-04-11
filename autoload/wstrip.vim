let s:pattern = '\s\+$'


function! s:cleanable() abort
  return buflisted(bufnr('%')) && empty(&buftype)
endfunction


function! s:git_repo() abort
  if !executable('git')
    return ''
  endif

  let repo = system('git rev-parse --show-toplevel')
  if v:shell_error
    return ''
  endif

  return fnamemodify(split(repo)[0], ':p')
endfunction


function! s:is_tracked(fname) abort
  call system(printf('git ls-files --full-name --error-unmatch "%s"', a:fname))
  return !v:shell_error
endfunction


function! s:get_diff_lines() abort
  if &readonly || !&modifiable || !empty(&buftype)
    echoe "File not writeable"
    return ["err"]
  endif

  let buf_name = bufname('%')
  if empty(buf_name) || !filereadable(buf_name)
    "return [[1, line('$')]]
    echoe "Buffer error or file unreadable"
    return ["err"]
  endif

  let repo = s:git_repo()
  let fullpath = fnamemodify(buf_name, ':p')
  let fname = fullpath
  if !empty(repo) && fname[:len(repo)-1] == repo
    let fname = fname[len(repo):]
  else
    let cwd = fnamemodify(getcwd(), ':p')
    if fname[:len(cwd)-1] == cwd
      let fname = fname[len(cwd):]
    else
      "return []
    endif
  endif

  if !empty(repo) && s:is_tracked(fullpath)
    let cmd = 'git diff -U0 --exit-code --no-ext-diff HEAD:"%s" "%s"'
  elseif executable('diff')
    let cmd = 'diff -U0 "%s" "%s"'
  else
    echoe "No diff command available"
    return ["err"]
  endif

  " This check is done before the file is written, so the buffer contents
  " needs to be compared with what's already written.  git-diff also requires
  " the file to exist inside of the working tree to diff against HEAD.
  let tmpfile = printf('%s/.wstrip.%s', fnamemodify(fullpath, ':h'),
        \ fnamemodify(fname, ':t'))

  let lines = getline(1, '$')
  if &fileformat ==# 'dos'
    call map(lines, 'v:val . "\r"')
  endif
  call writefile(lines, tmpfile)

  let difflines = split(system(printf(cmd, fname, tmpfile)), "\n")
  call delete(tmpfile)

  if v:shell_error == 0
    " No change
    return []
  elseif v:shell_error != 1
    echoe "Diff status bad"
    return ["err"]
  endif

  let groups = []

  for line in difflines
    if line !~# '^@@'
      continue
    endif

    " Only interested in added lines.  If a line is changed, it will show as a
    " deletion *and* addition.
    let added = matchstr(line, '+\zs[0-9,]\+')
    if added =~# ','
      let parts = map(split(added, ','), 'str2nr(v:val)')
      if !parts[1]
        continue
      endif
      let start_line = parts[0]
      let end_line = parts[0] + (parts[1] - 1)
    else
      let start_line = str2nr(added)
      let end_line = start_line
    endif
    call add(groups, [start_line, end_line])
  endfor

  return groups
endfunction


function! wstrip#clean(...) abort
  if !s:cleanable()
    echoe "File not cleanable"
    return
  endif

  let wspattern = s:pattern
  if !exists('b:wstrip_trailing_max')
    let b:wstrip_trailing_max = 0
  endif
  let wspattern = '\s\{'.b:wstrip_trailing_max.'}\zs'.wspattern

  if exists("a:1")
    if a:1 == "all"
      " remove all trailing whitespace in buffer
      let l:groups = [[1, line('$')]]
    elseif a:1 == "hide"
      " remove trailing whitespace highlighting
      syntax off
      return
    elseif a:1 == "show"
      " show or restore hidden trailing whitespace highlighting
      syntax on
      execute 'syntax match WStripTrailing '.'/'.wspattern.'/'.' containedin=ALL'
      return
    else
      echoe "Usage: WStrip [all | hide | show]"
      echom "WStrip with no argument removes trailing whitespace in buffer only on changed/new lines"
      echom "all : Remove all trailing whitespace in buffer"
      echom "hide: Hides trailing whitespace highlighting"
      echom "show: Shows trailing whitespace highlighting"
      return
    endif
  else
    let l:groups = s:get_diff_lines()
    if type(l:groups) != type([])
      echoe "s:get_diff_lines() return not a list"
      return
    endif
    if l:groups == []
      " buffer not changed, don't remove any trailing whitespace
      return
    elseif l:groups == ["err"]
      return
    else
      "Should be set(s) of line pairs that are non-zero numbers
      "e.g., minimal list: [[1,5]] ==> lines 1 to 5 modified
      "e.g., typical list: [[1,5],[10,10],[20,21]]
      "This is a basic check for a valid looking list (not exhaustive).
      let l:inner_list = get(l:groups, 0)
      if type(l:inner_list) != type([])
        echoe "s:get_diff_lines() return is not a nested list"
        return
      endif
      let l:first_line = get(l:inner_list, 0)
      if type(l:first_line) != type(0) || l:first_line == 0
        echoe "s:get_diff_lines() return is not list(s) of line pairs"
        return
      endif
    endif
  endif

  let view = winsaveview()
  for group in l:groups
    execute join(group, ',').'s/'.wspattern.'//e'
  endfor
  call histdel('search', -1)
  let @/ = histget('search', -1)
  call winrestview(view)
endfunction


function! wstrip#auto() abort
  if get(b:, 'wstrip_auto', get(g:, 'wstrip_auto', 0))
    call wstrip#clean()
  endif
endfunction


function! wstrip#syntax() abort
  if s:cleanable() && get(b:, 'wstrip_highlight', get(g:, 'wstrip_highlight', 1))
    let wspattern = s:pattern
    if exists('b:wstrip_trailing_max')
      let wspattern = '/\s\{'.b:wstrip_trailing_max.'}'.wspattern.'/ms=s+'.b:wstrip_trailing_max
    else
      let wspattern = '/'.wspattern.'/'
    endif

    execute 'syntax match WStripTrailing '.wspattern.' containedin=ALL'
  endif
endfunction
