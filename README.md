# wstrip.vim

Strip trailing whitespace only on changed lines.  Inspired by question on
StackExchange's [Vi and Vim][1] website.


## Summary

This plugin uses `git-diff` to trailing strip whitespace from lines that
you changed while editing.  This allows you to keep newly added lines clean
without affecting the history of existing lines.

If the file is not in a `git` repository, `diff` is used to make a simple
comparison against the existing file on disk.


## Usage

Trailing whitespace on only new or modified lines can be automatically stripped
when writing the buffer by setting `g:wstrip_auto` or `b:wstrip_auto` to `1`.  
This is disabled by default.

```vim
" Globally enabled for all filetypes
let g:wstrip_auto = 1  

" Just certain filetypes
autocmd FileType *.css,*.py let b:wstrip_auto = 1  
```

If you don't want automatic cleaning on write, the `:WStrip` command can 
still be used at any time to manually clean trailing whitespace on new or
changed lines of the current buffer. In addition the `:WStrip all` command
can be used to remove trialing whitespace on all lines of the buffer.

Trailing whitespace will be highlighted using the `WStripTrailing` syntax
group.  If it appears that Vim is capable of underlining text, trailing
whitespace will be highlighted as a red underline.  Otherwise, it will
highlighted with a red background.  To disable highlighting, set
`b:wstrip_highlight` to 0 or set `g:wstrip_highlight` to `0`.

```vim
" Disable trailing whitespace highlighting 
let g:wstrip_highlight = 0  
```

Trailing whitespace highlighting can still be turned on at any time,
regarless of the setting for wstrip_highlight, using the `:WStrip show` 
command. It can also be hidden again with `:WStrip hide`.  

If you want to allow a certain amount of trailing whitespace, you can set
`b:wstrip_trailing_max` to the maximum number of whitespace characters that are
allowed to remain, after cleaning, at the end of a line.  If not set, this
defaults to `2` for the `markdown` filetype. For all other filetypes it defaults
to `0`.

```vim
" Allow a maximum of 3 whitespaces characters to remain for all filetypes 
let b:wstrip_trailing_max = 3
```


## License

MIT

[1]: http://vi.stackexchange.com/q/7959/5229
