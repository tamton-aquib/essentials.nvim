
# essentials.nvim

Some tiny utility functions which i use locally.<br />

Not actually meant for external use because there are no config options. <br />
Instead you can copy paste these functions to your config.

The functions included are:
---

#### go_to_url()
Directing to url under the cursor. Will also work for stuff like "folke/tokyonight.nvim" <br/>
--> uses `xdg-open` in linux. <br />
How to use:

```lua
vim.api.nvim_set_keymap('n', 'gx', ':lua require"essentials".go_to_url()<CR>', {noremap=true, silent=true})
```
---

#### last_place()
Go to last edited place when entering a buffer. Example:
```lua
vim.cmd [[au BufEnter * lua require"essentials".last_place()]]
```
---

#### rename()
VSCodes floating like rename window. Example:
```lua
vim.api.nvim_set_keymap('n', '<F2>', ':lua require"essentials".rename()<CR>', {noremap=true, silent=true})
```
---

#### toggle_comment()
A small commenting function. (No multi-line comments). Example:
```lua
vim.api.nvim_set_keymap('n', '<C-_>', ':lua require"essentials".rename()<CR>', {noremap=true, silent=true})
vim.api.nvim_set_keymap('v', '<C-_>', ':lua require"essentials".toggle_comment(true)<CR>', {noremap=true, silent=true})
```
---

#### simple_fold()
Simple fold function. Example:
```lua
vim.cmd [[set foldtext=luaeval(\"require('essentials').simple_fold()\")]]
```
---

#### get_url()
Github link of the file with line numbers gets copied to clipboard (unstable).
--> Currently using weird stuff to copy to clipboard. Needs to be fixed.
```lua
vim.api.nvim_set_keymap('n', 'gl', ':lua require"essentials".get_url()<CR>', {noremap=true, silent=true})
```
---

#### swap_bool()
A function to swap bools. (true->false and false->true) Example:
```lua
vim.api.nvim_set_keymap('n', '<leader>s', ':lua require("essentials").swap_bool()<CR>', {noremap=true, silent=true})
```
---

#### cheat_sh()
Search stuff from https://cht.sh. Example:
```lua
vim.api.nvim_set_keymap('n', '<leader>cs', ':lua require"essentials".cheat_sh()<CR>', {noremap=true, silent=true})
```
