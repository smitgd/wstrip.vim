command! -nargs=? WStrip call wstrip#clean(<f-args>)

if has('gui') || !empty(system('tput smul'))
  highlight default WStripTrailing ctermfg=red cterm=underline guifg=red gui=underline
  "highlight default WStripTrailing ctermbg=lightgrey guibg=lightgrey
else
  highlight default WStripTrailing ctermbg=red guibg=red
endif


augroup wstrip
  autocmd BufWritePre * call wstrip#auto()
  autocmd Syntax * call wstrip#syntax()
augroup END
