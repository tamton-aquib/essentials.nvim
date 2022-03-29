
# essentials.nvim

Some tiny utility functions which i use locally.<br />

Not actually meant for external use because there are no config options. <br />
Instead you could fork the repo or copy paste these functions to your config.


The functions included are:

#### Go to a url under the cursor
Will also work for stuff like `folke/tokyonight.nvim` or \[link](https://github.com) <br />
> uses `xdg-open` in linux. <br />
> use go_to_url("start") for windows.

```vim
nnoremap gx :lua require("essentials").go_to_url()<CR>
```
---

#### Go to the last place when opening a buffer
```vim
vim.cmd [[au BufReadPost * lua require("essentials").last_place()]]
```

---

#### Run different programming languages
Run files according to filetypes and commands.
```vim
nnoremap <leader>r :lua require("essentials").run_file()<CR>
```

---

#### VSCode like floating window to rename.
> Uses vim.lsp.buf.rename()
```vim
nnoremap <F2> :lua require("essentials").rename()<CR>
```
---

#### Simple Commenting function
A 20LOC function for commenting. (No multi-line comments).
```vim
nnoremap <C-_> :lua require("essentials").toggle_comment()<CR>
vnoremap <C-_> :lua require("essentials").toggle_comment(true)<CR>
```
---

#### Small fold function.
Simple fold function. Example:
```lua
vim.opt.foldtext = 'v:lua.require("essentials").simple_fold()'
```

---

#### Copy the git link of the current line range
Copies it to clipboard.
```vim
nnoremap gl :lua require("essentials").get_git_url()<CR>
```
---

#### Swap Booleans
A function to swap bools. 
> (true->false and false->true)
```vim
nnoremap <leader>s :lua require("essentials").swap_bool()<CR>
```
---

#### Search results from cht.sh
Search programming doubts inside neovim with cheat.sh
> Gets current filetype and searches accordingly.

```vim
nnoremap <leader>cs :lua require("essentials").cheat_sh()<CR>
```
