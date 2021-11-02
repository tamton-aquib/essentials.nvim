local M = {}
local line = vim.fn.line
local exp = vim.fn.expand

-------- Run code according to filetypes ---------
function M.run_file()
	local filename = exp('%:t')
	local filetypes = {
		rust	   = "cargo run",
		python	   = "python "..filename,
		javascript = "npm start",
		javascriptreact = "npm start",
		java	   = "javac ".. filename.." && java "..exp('%:t:r').." && rm *.class",
		c	       = "gcc -o noice "..filename.." && ./noice"
	}

	local command = filetypes[vim.bo.filetype]
	if command ~= nil then
		require("toggleterm.terminal").Terminal:new{
			cmd=command, close_on_exit = false,
		}:toggle()
		print("Running: "..command)
	end
end
--------------------------------------------------

-------- VSCode like rename function -------
function M.post(rename_old, winnr)
    local new = vim.api.nvim_get_current_line()
    vim.api.nvim_win_close(winnr, true)
    vim.lsp.buf.rename(vim.trim(new))
    print(rename_old..' -> '..new)
    vim.cmd [[stopinsert!]]
end

function M.rename()
    local rename_old = vim.fn.expand('<cword>')
    local noice_buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(
    noice_buf, true,
    {
        relative='cursor',
        row=1, col=1,
        width=10, height=1,
        style='minimal', border='single',
    })
    vim.cmd [[startinsert]]
    vim.api.nvim_buf_set_keymap(
        noice_buf, 'i', '<CR>',
        '<cmd>lua require"essentials".post("'..rename_old..','..win..'")<CR>',
        {noremap=true, silent=true}
    )
end
--------------------------------------------

---------- comment function ---------
local comment_map = {
    javascript = '//', typescript = '//', javascriptreact = '//',
    c = '//', java = '//', rust	= '//', cpp = '//',
    python = '#', sh = '#', conf = '#', dosini = '#', yaml = '#',
    lua		= '--',
}

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
-------------------------------------

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

function M.get_url()
    local final = parse_url()
    local git_file = vim.fn.expand('%:p'):match(git_root().."(.+)")
    local starting, ending = vim.fn.getpos("'<")[2], vim.fn.getpos("'>")[2]

    local noice = ("https://github.com/%s/blob/%s%s#L%s-L%s"):format(
        final, git_branch(), git_file, starting, ending
    )

    os.execute([[python -c "import pyperclip; pyperclip.copy(']]..noice..[[')"]])
    print("link copied to clipboard!")
    -- os.execute('xdg-open '..noice)
end
--------------------------------

--------- clean folds ----------
function M.simple_fold()
    local fs, fe = vim.v.foldstart, vim.v.foldend
    local start_line = vim.fn.getline(fs):gsub("\t", ("\t"):rep(vim.o.tabstop))
    local end_line = vim.trim(vim.fn.getline(fe))
    local spaces = (" "):rep( vim.o.columns - start_line:len() - end_line:len() - 7)

    return start_line .. "  " .. end_line .. spaces
end
-- set this to activate: set foldtext=luaeval(\"require('essentials').simple_fold()\")
---------------------------------

-------- Swap booleans ----------
function M.swap_bool()
    local c = vim.api.nvim_get_current_line()
    local subs = c:match("true") and c:gsub("true", "false") or c:gsub("false", "true")
    vim.api.nvim_set_current_line(subs)
end
---------------------------------

----- Go to last edited place -----
function M.last_place()
    -- if vim.api.nvim_win_is_valid(0) and vim.api.nvim_buf_is_loaded(0) then
    if vim.tbl_contains(vim.api.nvim_list_bufs(), vim.api.nvim_get_current_buf()) then
        if not vim.tbl_contains({"help", "packer", "toggleterm"}, vim.bo.ft) then
            if line [['"]] > 1 and line [['"]] <= line("$") then
                vim.cmd [[norm '"]]
            end
        end
    end
end
-----------------------------------

-----Go To URL-------
function M.go_to_url()
	local url = vim.api.nvim_get_current_line():match([[%[.*]%((.*)%)]]) -- To work on md links
	if url == nil then
		url = vim.fn.expand('<cWORD>')
		if not string.match(url, 'http') then url = "https://github.com/"..url end
		if string.match(url, [[(.+),$]]) then url = url:sub(1,-2) end -- to check commas at the end
	end

    vim.notify("Going to "..url, 'info', {title="Opening browser..."})
    vim.cmd(':silent !xdg-open '..url..' 1>/dev/null')
end
-- [md-link-example](https://github.com/tamton-aquib/essentials.nvim)
---------------------

-------- cht.sh function --------------
function M.getword()
	local nice_word = vim.trim(vim.fn.getline('.'))
	vim.cmd [[q]]

	local noice = vim.fn.join(vim.split(nice_word, " "), "+")
	require ("toggleterm.terminal").Terminal:new{
		cmd=('curl cht.sh/%s/%s'):format(vim.bo.ft, noice),
		float_opts = { border='double' },
		on_open = function(term)
			vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
			vim.cmd [[stopinsert!]]
		  end,
	}:toggle()
end

function M.cheat_sh()
	local buf = vim.api.nvim_create_buf(false, true)

	local height, width = vim.o.lines, vim.o.columns
    local w = math.ceil(width * 0.7)
    local row = math.ceil((height) / 2 - 3)
    local col = math.ceil((width - w) / 2)
	vim.api.nvim_open_win(buf, true, {
		relative='win', row=row, col=col, width=w, height=1, style='minimal', border='rounded'
	})
	vim.api.nvim_buf_set_keymap(0, 'i', '<CR>', '<cmd>lua require("essentials").getword()<CR>', {noremap=true})
	vim.api.nvim_feedkeys('i', 'n', true)
end
---------------------------------------

return M
