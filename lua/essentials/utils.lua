local U = {}
local log_levels = { [3]="Warn", [4]="Error", [2]="Info" }
local current_line = 1

U.set_quit_maps = function()
    vim.keymap.set('n', 'q', ':bd!<CR>', { buffer=true, silent=true })
    vim.keymap.set('n', '<ESC>', ':bd!<CR>', { buffer=true, silent=true })
    vim.keymap.set('n', '<C-c>', ':bd!<CR>', { buffer=true, silent=true })
end

--- Minimal floating notify window.
---@param msg string
---@param level number or vim.lsp.log_levels
---@param lopts table
U.ui_notify = function(msg, level, lopts)
    local content = vim.split(vim.trim(msg), '\n')
    lopts = lopts or {}
    local hl = log_levels[level] or "Hint"

    if #content >= 10 then
        vim.api.nvim_echo(vim.tbl_map(function(i) return {i.."\n", log_levels[level]} end, content), true, {})
        return
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].ft = "notify"

    local maxlen = math.max(unpack(vim.fn.map(content, 'strwidth(v:val)'))) + 1
    maxlen = math.min(math.max(maxlen, 20), vim.o.columns-2)

    local win = vim.api.nvim_open_win(buf, false, {
        relative='editor', style='minimal', border='rounded', noautocmd=true,
        row=current_line, col=vim.o.columns-maxlen, width=maxlen, height=#content
    })
    vim.api.nvim_win_set_option(win, 'winhighlight', 'Normal:DiagnosticSign'..hl)
    vim.api.nvim_win_set_option(win, 'winhighlight', 'FloatBorder:DiagnosticSign'..hl)
    vim.api.nvim_buf_set_lines(buf, 0, #content, false, content)
    current_line = current_line + #content + 1

    vim.defer_fn(function()
        if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
        if vim.api.nvim_buf_is_valid(win) then vim.api.nvim_buf_delete(buf, {force=true}) end
        current_line = current_line - #content - 1
    end, lopts.timeout or 5000)
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
    local titles = vim.iter(ipairs(choices)):map(function(i, choice)
        return i..": "..(opts.format_item or tostring)(choice)
    end):totable()

    local max = vim.iter(titles):fold(0, function(t, s)
        return s:len() > t and s:len() or t
    end)
    max = math.min(math.max(max, opts.prompt and opts.prompt:len() or 20), 80)

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_open_win(buf, true, {
        style='minimal', border=o.border or 'double', relative='cursor',
        row=1, col=1, width=o.width or max+1, height=#choices, title=opts.prompt
    })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, titles)
    U.set_quit_maps()

    local post_select = function(i)
        pcall(vim.api.nvim_buf_delete, buf, {force=true})
        callback(choices[i])
    end

    for i=1,#choices do
        vim.api.nvim_buf_add_highlight(buf, 0, 'Identifier', i-1, 0, 3)
        vim.keymap.set('n', tostring(i), function() post_select(i) end)
    end
    vim.keymap.set('n', '<CR>', function() post_select(vim.api.nvim_win_get_cursor(0)[1]) end)
end

--- vim.ui.input emulation in a float
---@param opts table: usual opts like in vim.ui.input()
---@param callback function: callback to invoke
-- TODO: implement as blocking, and no prompts as of now
-- TODO: prompt buf, prompt_setcallback() etc
U.ui_input = function(opts, callback)
    local buf = vim.api.nvim_create_buf(false, true)

    vim.api.nvim_open_win(buf, true, {
        relative='cursor', style='minimal', border='single',
        row=1, col=1, width=opts.width or 20, height=1, title=opts.prompt
    })
    U.set_quit_maps()
    if opts.default then vim.api.nvim_put({opts.default}, "", true, true) end
    vim.cmd [[startinsert!]]

    vim.keymap.set({'i', 'n'}, '<CR>', function()
        local content = vim.api.nvim_get_current_line()
        -- if opts.prompt then content = content:gsub(opts.prompt, '') end
        vim.cmd [[bd | stopinsert!]]
        callback(vim.trim(content))
    end, {buffer=true, silent=true})
end

return U
