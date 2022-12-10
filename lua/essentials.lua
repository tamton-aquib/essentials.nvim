local E = {}
local U = require("essentials.utils")
local term_buf, term_win

E.ui_input = U.ui_input
E.ui_select = U.ui_select
E.ui_picker = U.ui_picker
E.ui_notify = U.ui_notify

---> Share the file or a range of lines over https://0x0.st .
E.null_pointer = function()
    local from, to = vim.api.nvim_buf_get_mark(0, "<")[1], vim.api.nvim_buf_get_mark(0, ">")[1]
    local file = vim.fn.tempname()
    vim.cmd(":silent! ".. (from == to and "" or from..","..to).."w "..file)

    vim.fn.jobstart({"curl", "-sF", "file=@"..file.."", "https://0x0.st"}, {
        stdout_buffered=true,
        on_stdout=function(_, data)
            vim.fn.setreg("+", data[1])
            vim.notify("Copied "..data[1].." to clipboard!")
        end,
        on_stderr=function(_, data) if data then print(table.concat(data)) end end
    })
end

--> Open a simple/single terminal with few opts. (toggleable)
---@param cmd string: command to run
---@param direction string: direction to open. ex: "h"/"v"/"t"
---@param close boolean: close_on_exit
E.toggle_term = function(cmd, direction, close)
    local dir_cmds = { h = "split", v = "vsplit", t = "" }

    local set_layout = function()
        vim.cmd(dir_cmds[direction or 'h'])
        term_win = vim.api.nvim_get_current_win()
    end
    local call_term = function()
        -- vim.fn.termopen(cmd, { on_exit = function(_) if close then vim.cmd.bd() end end })
        vim.cmd("term "..(cmd and cmd or vim.opt.shell:get()))
        term_buf = vim.api.nvim_get_current_buf()
        if close then
            vim.cmd("au TermClose * ++once bd")
            if direction == 't' then term_buf, term_win = nil, nil end
        end
    end
    if term_buf == nil or term_win == nil then
        set_layout()
        call_term()
        return
    end

    local buf_exists = function() return vim.api.nvim_buf_is_valid(term_buf) end
    local win_exists = function() return vim.api.nvim_win_is_valid(term_win) end

    if not buf_exists() and not win_exists() then
        set_layout()
        call_term()
    elseif not buf_exists() and win_exists() then
        vim.api.nvim_set_current_buf(term_buf)
    elseif buf_exists() and not win_exists() then
        set_layout()
        vim.api.nvim_set_current_buf(term_buf)
    elseif buf_exists() and win_exists() then
        vim.api.nvim_win_hide(term_win)
    end
end

--> Run the current file according to filetype
---@param ht number: for height or "v" for vertical
E.run_file = function(ht)
    local fts = {
        rust       = "cargo run",
        python     = "python %",
        javascript = "npm start",
        c          = "make",
        cpp        = "make",
        java       = "java %"
    }

    local cmd = fts[vim.bo.ft]
    vim.cmd(
        cmd and ("w | " .. (ht or "") .. "sp | term " .. cmd)
        or "echo 'No command for this filetype'"
    )
end

--> VScode like rename function
E.rename = function()
    local rename_old = vim.fn.expand('<cword>')
    E.ui_input({ width=15 }, function(input)
        if vim.lsp.buf.server_ready() == true then
            vim.lsp.buf.rename(vim.trim(input))
            vim.notify(rename_old..' -> '..input)
        else
            vim.notify("LSP Not ready yet!")
        end
    end)
end

local comment_map = {
    javascript = '//', typescript = '//', javascriptreact = '//',
    c = '//', java = '//', rust = '//', cpp = '//', lua = '--',
    python = '#', sh = '#', conf = '#', dosini = '#', yaml = '#',
}

--> A Simple comment toggling function.
--> tried commentstring but something was off.
---@param visual boolean
E.toggle_comment = function(visual)
    local startrow, endrow = vim.fn.getpos("'<")[2], vim.fn.getpos("'>")[2]
    -- local startrow, endrow = vim.fn.getpos("v")[2], vim.fn.getpos(".")[2]

    local leader = comment_map[vim.bo.ft] or "//"
    local current_line = vim.api.nvim_get_current_line()
    local cursor_position = vim.api.nvim_win_get_cursor(0)
    local noice = visual and startrow..','..endrow or ""

    vim.cmd(current_line:find("^%s*"..vim.pesc(leader))
        and noice..'norm ^'..('x'):rep(#leader+1)
        or noice..'norm I'..leader..' ')

    vim.api.nvim_win_set_cursor(0, cursor_position)
    -- if visual then vim.cmd [[norm gv]] end
end

--- A simple and clean fold function
---@return string: foldtext
E.simple_fold = function()
    local fs, fe = vim.v.foldstart, vim.v.foldend
    local start_line = vim.fn.getline(fs):gsub("\t", ("\t"):rep(vim.opt.ts:get()))
    local end_line = vim.trim(vim.fn.getline(fe))
    local spaces = (" "):rep( vim.o.columns - start_line:len() - end_line:len() - 7)

    return start_line .. "  " .. end_line .. spaces
end
-- set this: vim.opt.foldtext = 'v:lua.require("essentials").simple_fold()'

--> A function to swap bools
E.swap_bool = function()
    local c = vim.api.nvim_get_current_line()
    local subs = c:match("true") and c:gsub("true", "false") or c:gsub("false", "true")
    vim.api.nvim_set_current_line(subs)
end

---> Go to last edited place
E.last_place = function()
    -- local markpos = vim.api.nvim_buf_get_mark(0, '"')
    local _, row, col, _ = unpack(vim.fn.getpos([['"]]))
    -- if markpos then
    -- local row, col = unpack(markpos)
    local last = vim.api.nvim_buf_line_count(0)
    if (row > 0 or col > 0) and (row <= last) then vim.cmd([[norm! '"]]) end
    -- end
end

--> Go to url under cursor (works on md links too)
---@param cmd string: the cli command to open browser. ex: "start","xdg-open"
E.go_to_url = function(cmd)
    local url = vim.fn.expand('<cfile>', nil, nil)
    if not url:match("http") then
        url = "https://github.com/"..url
    end

    vim.notify("Going to "..url, 'info', { title="Opening browser..." })
    vim.fn.jobstart({cmd or "xdg-open", url}, {on_exit=function() end})
end

--> cht.sh function
E.cheat_sh = function()
    E.ui_input({ width=30 }, function(query)
        query = table.concat(vim.split(query, " "), "+")
        local cmd = ('curl "https://cht.sh/%s/%s"'):format(vim.bo.ft, query)
        vim.cmd("split | term " .. cmd)
        vim.cmd [[stopinsert!]]
        U.set_quit_maps()
    end)
end

return E
