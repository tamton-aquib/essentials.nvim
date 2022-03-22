local U = {}

U.set_quit_maps = function()
	vim.keymap.set('n', 'q', ':bd!<CR>', {buffer=true, silent=true})
	vim.keymap.set('n', '<Esc>', ':bd!<CR>', {buffer=true, silent=true})
end

-- TODO: implement with blocks
U.ui_input = function(opts, callback)
	local buf = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_open_win(buf, true, {
		relative='cursor', style='minimal', border='single',
		row=1, col=1, width=opts.width or 15, height=1
	})
	U.set_quit_maps()
	vim.cmd [[startinsert]]

	vim.keymap.set('i', '<CR>', function()
		-- local content = vim.trim(vim.api.nvim_get_current_line())
		vim.cmd [[q | stopinsert!]]
		callback(vim.trim(vim.fn.getline('.')))

	end, {buffer=true, silent=true})
end

return U
