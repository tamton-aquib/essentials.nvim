# essentials.nvim

Some tiny utility functions which i use locally.<br />

Not actually meant for external use because there are no config options. <br />
Instead you could fork the repo or copy paste the functions to your config.


> Requires nvim version: 0.7.

The functions included are:

#### Go to url under the cursor
Will also work for stuff like `folke/tokyonight.nvim` or \[link](https://github.com) <br />
> uses `xdg-open` in linux. <br />
> use go_to_url("start") for windows. #untested

![go_to_url](https://user-images.githubusercontent.com/77913442/163594602-b2f616f5-0d1d-4d24-9c3d-7fef0efefadd.gif)
```vim
nnoremap gx :lua require("essentials").go_to_url()<CR>
```
---

#### Go to the last place when opening a buffer
```vim
autocmd BufReadPost * lua require("essentials").last_place()
```

---

#### Run different programming languages
Run files according to filetypes and commands.

![run_file](https://user-images.githubusercontent.com/77913442/163594688-a253cbff-4ee4-4afb-ba4b-45117e09badc.gif)
```vim
nnoremap <leader>r :lua require("essentials").run_file()<CR>
```

---

#### VSCode like floating window to rename.
> Uses vim.lsp.buf.rename()

![rename](https://user-images.githubusercontent.com/77913442/163594637-d4047a95-f748-4d59-95dc-9324f7e14bd7.gif)
```vim
nnoremap <F2> :lua require("essentials").rename()<CR>
```
---

#### Simple Commenting function
A 20LOC function for commenting. (No multi-line comments).

![toggle_comment](https://user-images.githubusercontent.com/77913442/163594893-d9e1e289-40b9-439b-ab08-6e01f84ff058.gif)
```vim
nnoremap <C-_> :lua require("essentials").toggle_comment()<CR>
vnoremap <C-_> :lua require("essentials").toggle_comment(true)<CR>
```
---

#### A smol fold function.
Simple fold function. Example:

![simple_fold](https://user-images.githubusercontent.com/77913442/163594826-9e635b2f-7635-49e8-996d-0ec86f2cdc87.gif)
```lua
vim.opt.foldtext = 'v:lua.require("essentials").simple_fold()'
```

---

#### Swap Booleans
A function to swap bools. 
> (true->false and false->true)

![swap_bool](https://user-images.githubusercontent.com/77913442/163594860-425702b5-8c8f-42ac-a899-b41ea31d83da.gif)
```vim
nnoremap <leader>s :lua require("essentials").swap_bool()<CR>
```
---

#### Search results from cht.sh
Search programming doubts inside neovim with cheat.sh
> Gets current filetype and searches accordingly.

![cheat_sheet](https://user-images.githubusercontent.com/77913442/163594529-eaa5e387-6a22-4570-8b14-805e586d6298.gif)
```vim
nnoremap <leader>cs :lua require("essentials").cheat_sh()<CR>
```
