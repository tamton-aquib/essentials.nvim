local U = {}

U.set_quit_maps = function()
    vim.keymap.set('n', 'q', ':bd!<CR>', { buffer=true, silent=true })
    vim.keymap.set('n', '<ESC>', ':bd!<CR>', { buffer=true, silent=true })
end

--- A wrapper around telescope.
---@param tbl table: tbl to be picked
---@param opts table: options(prompt_title, etc)
---@param callback function: (to be invoked)
U.ui_picker = function(tbl, opts, callback)
    local actions = require("telescope.actions")
    local finders = require("telescope.finders")
    local pickers = require("telescope.pickers")
    local action_state = require("telescope.actions.state")

    local do_stuff = function(buf)
        actions.close(buf)
        local result = action_state.get_selected_entry()[1]
        vim.schedule(function() callback(result) end)
    end

    pickers.new(opts or {}, {
        prompt_title = opts.prompt_title or "Picker",
        finder = finders.new_table(assert(tbl or "No table provided")),
        attach_mappings = function(buf, map)
            map("i", "<CR>", function() do_stuff(buf) end)
            map("n", "<CR>", function() do_stuff(buf) end)
            return true
        end
    }):find()
end

--- vim.ui.select emulation in a float.
---@param choices table: list of choices
---@param opts table: options(border, width, hl)
---@param callback function
U.ui_select = function(choices, opts, callback)
    local o = opts or {}
    local titles = vim.fn.map(choices, function(i, choice)
        return i+1 .. ": " .. (type(choice) == 'table' and choice[2].title or choice)
    end)
    ---@diagnostic disable-next-line: unused-local
    local max = vim.fn.max(vim.fn.map(titles, 'strwidth(v:val)'))
    max = (max > 50 and 50 or max) < 20 and 20 or max
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_open_win(buf, true, {
        style='minimal', border=o.border or 'double', relative='cursor',
        row=1, col=1, width=o.width or max, height=#choices
    })
    vim.api.nvim_put(titles, "", false, false)

    local m_id = vim.fn.matchadd(o.hl or "keyword", "\\zs\\d:\\ze")
    vim.defer_fn(function()
        local selection = string.char(vim.fn.getchar())
        callback(choices[tonumber(selection)])
        -- TODO: no need to clear ig cos matchadd is local to win
        vim.fn.matchdelete(m_id)
        vim.api.nvim_buf_delete(buf, {force=true})
    end, 50)
end

-- TODO: implement as blocking, and no prompts as of now
--- vim.ui.input emulation in a float
---@param opts table: usual opts like in vim.ui.input()
---@param callback function: callback to invoke
U.ui_input = function(opts, callback)
    local buf = vim.api.nvim_create_buf(false, true)

    vim.api.nvim_open_win(buf, true, {
        relative='cursor', style='minimal', border='single',
        row=1, col=1, width=opts.width or 15, height=1
    })
    U.set_quit_maps()
    if opts.default then vim.api.nvim_put({opts.default}, "", true, true) end
    vim.cmd [[startinsert!]]

    vim.keymap.set('i', '<CR>', function()
        local content = vim.api.nvim_get_current_line()
        -- if opts.prompt then content = content:gsub(opts.prompt, '') end
        vim.cmd [[q | stopinsert!]]
        callback(vim.trim(content))
    end, {buffer=true, silent=true})
end

return U
