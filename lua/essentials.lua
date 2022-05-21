local E = {}
local U = require("essentials.utils")

E.ui_input = U.ui_input
E.ui_select = U.ui_select
E.ui_picker = U.ui_picker

--> Open a simple terminal with few opts.
---@param cmd string: command to run
---@param direction string: direction to open. ex: "h"/"v"/"t"
---@param close boolean: close_on_exit
E.open_term = function(cmd, direction, close)
    local dir_cmds = { h = "split | enew!", v = "vsplit | enew!", t = "enew!" }
    vim.cmd(dir_cmds[direction or 'h'])
    vim.fn.termopen(cmd, { on_exit = function(_) if close then vim.cmd('bd') end end })
end

--> Run the current file according to filetype
---@param ht number: for height or "v" for vertical
function E.run_file(ht)
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
        cmd and ("w | " .. (ht or "") .. "split | terminal " .. cmd)
        or "echo 'No command for this filetype'"
    )
end

--> VScode like rename function
function E.rename()
    local rename_old = vim.fn.expand('<cword>')
    E.ui_input({ width=15 }, function(input)
        if vim.lsp.buf.server_ready() == true then
            vim.lsp.buf.rename(vim.trim(input))
            vim.notify(rename_old..' -> '..input)
        else
            print("LSP Not ready yet!")
        end
    end)
end

local comment_map = {
    javascript = '//', typescript = '//', javascriptreact = '//',
    c = '//', java = '//', rust = '//', cpp = '//',
    python = '#', sh = '#', conf = '#', dosini = '#', yaml = '#',
    lua	= '--',
}

--> A Simple comment toggling function.
---@param visual boolean
function E.toggle_comment(visual)
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

---------- git links -----------
-- This was removed, now i use: https://github.com/rktjmp/paperplanes.nvim
--------------------------------

--- A simple and clean fold function
---@return string: foldtext
function E.simple_fold()
    local fs, fe = vim.v.foldstart, vim.v.foldend
    local start_line = vim.fn.getline(fs):gsub("\t", ("\t"):rep(vim.opt.ts:get()))
    local end_line = vim.trim(vim.fn.getline(fe))
    local spaces = (" "):rep( vim.o.columns - start_line:len() - end_line:len() - 7)

    return start_line .. "  " .. end_line .. spaces
end
-- set this: vim.opt.foldtext = 'v:lua.require("essentials").simple_fold()'

--> A function to swap bools
function E.swap_bool()
    local c = vim.api.nvim_get_current_line()
    local subs = c:match("true") and c:gsub("true", "false") or c:gsub("false", "true")
    vim.api.nvim_set_current_line(subs)
end

---> Go to last edited place
function E.last_place()
    local markpos = vim.api.nvim_buf_get_mark(0, '"')
    if markpos then
        local row, col = unpack(markpos)
        local last = vim.api.nvim_buf_line_count(0)
        if (row > 0 or col > 0) and (row <= last) then vim.cmd [[norm! '"]] end
    end
end

--> Go to url under cursor (works on md links too)
---@param cmd string: the cli command to open browser. ex: "start","xdg-open"
function E.go_to_url(cmd)
    local url = vim.api.nvim_get_current_line():match([[%[.*]%((.*)%)]]) -- To work on md links
    if not url then
        url = vim.fn.expand('<cWORD>')
        if not url:match('http') then url = "https://github.com/"..url end
        if url:match([[(.+)[,:]$]]) then url = url:sub(1,-2) end -- to check commas at the end
    end

    vim.notify("Going to "..url, 'info', { title="Opening browser..." })
    vim.cmd(':silent !'..(cmd or "xdg-open")..' '..url..' 1>/dev/null')
end

--> cht.sh function
function E.cheat_sh()
    E.ui_input({ width=30 }, function(query)
        query = table.concat(vim.split(query, " "), "+")
        local cmd = ('curl "https://cht.sh/%s/%s"'):format(vim.bo.ft, query)
        vim.cmd("split | term " .. cmd)
        vim.cmd [[stopinsert!]]
        U.set_quit_maps()
    end)
end

return E
