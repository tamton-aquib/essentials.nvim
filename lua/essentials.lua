local M = {}
local line = vim.fn.line
local map = vim.api.nvim_buf_set_keymap

--> Open a simple terminal.
---@param cmd string: command to run
---@param direction string: direction to open
---@param close string: close_on_exit
M.open_term = function(cmd, direction, close)
	local dir_cmds = { h = "split | enew!", v = "vsplit | enew!", t = "enew!" }
	vim.cmd(dir_cmds[direction or 'h'])
	vim.fn.termopen(cmd, { on_exit = function(_) if close then vim.cmd('bd') end end })
end

--> Run the current file according to specific commands
---@param height number: for size or "v" for vertical
function M.run_file(height)
	local fts = {
		rust       = "cargo run",
		python     = "python %",
		javascript = "npm start",
		c          = "make",
		cpp        = "make",
	}

	local cmd = fts[vim.bo.ft]
	vim.cmd(
		cmd and ("w | "..(height or "").."split | terminal "..cmd) or
		[[echo 'No command Specified for this filetype!']]
	)
end

--> VScode like rename function
-- TODO: Add ui.input as a float
function M.rename()
	local new
	local rename_old = vim.fn.expand('<cword>')
	vim.ui.input({prompt="Enter new: "}, function(input) new=input end)
	vim.lsp.buf.rename(vim.trim(new))
	vim.notify(rename_old..' -> '..new)
end

local comment_map = {
	javascript = '//', typescript = '//', javascriptreact = '//',
	c = '//', java = '//', rust = '//', cpp = '//',
	python = '#', sh = '#', conf = '#', dosini = '#', yaml = '#',
	lua	= '--',
}

--- A Simple comment toggling function.
---@param visual boolean
function M.toggle_comment(visual)
	local starting, ending = vim.fn.getpos("'<")[2], vim.fn.getpos("'>")[2]

	local leader = comment_map[vim.bo.ft]
	local current_line = vim.api.nvim_get_current_line()
	local cursor_position = vim.api.nvim_win_get_cursor(0)
	local noice = visual and starting..','..ending or ""

	vim.cmd(current_line:find("^%s*"..vim.pesc(leader))
		and noice..'norm ^'..('x'):rep(#leader+1)
		or noice..'norm I'..leader..' ')

	vim.api.nvim_win_set_cursor(0, cursor_position)
	-- if visual then vim.cmd [[norm gv]] end
end

---------- git links -----------
local function git_stuff(args)
	return require('plenary.job'):new({ command = 'git', args = args }):sync()[1]
end

local function git_url() return git_stuff({ 'config', '--get', 'remote.origin.url' }) end
local function git_branch() return git_stuff({ 'branch', '--show-current' }) end
local function git_root() return git_stuff({ 'rev-parse', '--show-toplevel' }) end

local function parse_url()
	local url = git_url()
	if not url then error("No git remote found!") return end

	return url:match("https://github.com/(.+)$") or url:match("git@github.com:(.+).git$")
end

function M.get_git_url()
	local final = parse_url()
	local git_file = vim.fn.expand('%:p'):match(git_root().."(.+)")
	local starting, ending = vim.fn.getpos("'<")[2], vim.fn.getpos("'>")[2]

	local url = ("https://github.com/%s/blob/%s%s#L%s-L%s"):format(
		final, git_branch(), git_file, starting, ending
	)

	vim.fn.setreg('+', url)
	print(url .. " copied to clipboard!")
	-- os.execute('xdg-open '..noice)
end
--------------------------------

--- A simple and clean fold function
---@return string: foldtext
function M.simple_fold()
	local fs, fe = vim.v.foldstart, vim.v.foldend
	local start_line = vim.fn.getline(fs):gsub("\t", ("\t"):rep(vim.o.tabstop))
	local end_line = vim.trim(vim.fn.getline(fe))
	local spaces = (" "):rep( vim.o.columns - start_line:len() - end_line:len() - 7)

	return start_line .. "  " .. end_line .. spaces
end
-- set this: vim.opt.foltext = 'v:lua.require("essentials").simple_fold()'

--> A function to swap bools
function M.swap_bool()
	local c = vim.api.nvim_get_current_line()
	local subs = c:match("true") and c:gsub("true", "false") or c:gsub("false", "true")
	vim.api.nvim_set_current_line(subs)
end

---> Go to last edited place
function M.last_place()
	-- if vim.api.nvim_win_is_valid(0) and vim.api.nvim_buf_is_loaded(0) then
	if vim.tbl_contains(vim.api.nvim_list_bufs(), vim.api.nvim_get_current_buf()) then
		if not vim.tbl_contains({"help", "packer", "toggleterm"}, vim.bo.ft) then
			if line [['"]] > 1 and line [['"]] <= line("$") then
				vim.cmd [[norm '"]] -- g'" for including column
			end
		end
	end
end

--> Go to url under cursor (works on md links too)
---@param cmd string: the cli command to open browser
function M.go_to_url(cmd)
	local url = vim.api.nvim_get_current_line():match([[%[.*]%((.*)%)]]) -- To work on md links
	if url == nil then
		url = vim.fn.expand('<cWORD>')
		if not string.match(url, 'http') then url = "https://github.com/"..url end
		if string.match(url, [[(.+)[,:]$]]) then url = url:sub(1,-2) end -- to check commas at the end
	end

	vim.notify("Going to "..url, 'info', {title="Opening browser..."})
	vim.cmd(':silent !'..(cmd or "xdg-open")..' '..url..' 1>/dev/null')
end

--> cht.sh function
-- TODO: add ui.input as float
function M.cheat_sh()
	local query
	vim.ui.input({prompt="Enter query: "}, function(inp) query=inp end)

	local cmd = ('curl "cht.sh/%s/%s"'):format(vim.bo.ft, query)
	vim.cmd("split | term " .. cmd)
	vim.cmd [[stopinsert]]

	map(0, 'n', 'q', ':bd!<CR>', {noremap=true, silent=true})
	map(0, 'n', '<Esc>', ':bd!<CR>', {noremap=true, silent=true})
end

return M
