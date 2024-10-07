local api, fn, uv = vim.api, vim.fn, vim.uv
local command = api.nvim_create_user_command
local wrap = vim.schedule_wrap

local init_win = function(vertical)
    local bufnr = api.nvim_create_buf(false, true)
    assert(bufnr ~= 0, "failed to create buffer")

    api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })

    api.nvim_open_win(bufnr, false, {
        vertical = vertical or false,
        win = 0,
    })

    return bufnr
end

local handler = function(bufnr)
    return wrap(function(err, stdio)
        if stdio then
            stdio = stdio:gsub("\r\n", "\n")
            local out = vim.split(stdio, "\n")
            api.nvim_buf_set_lines(bufnr, -2, -1, true, out)
        end
    end)
end

local shell_cmd = function(bufnr, cmd, input, vertical, error)
    local shell_cmd = { "sh", "-c", cmd }
    local stdin = #input > 0 and input or nil
    local stdout = handler(bufnr)

    local stderr
    if error then
        local err_bufnr = init_win(vertical)
        stderr = handler(err_bufnr)
    end

    vim.system(shell_cmd, {
        text = true,
        stdin = stdin,
        stdout = stdout,
        stderr = stderr,
    })
end

local redir = function(kwargs)
    local cmd = kwargs.args
    local stderr = kwargs.bang
    local vert = kwargs.smods.vertical
    local range = kwargs.range

    local bufnr = init_win(vertical)

    if cmd:sub(1, 1) == "!" then
        local input = {}
        if range ~= 0 then
            local l_1 = kwargs.line1 - 1
            local l_2 = kwargs.line2
            input = api.nvim_buf_get_lines(0, l_1, l_2, true)
        end
        shell_cmd(bufnr, cmd:sub(2), input, vertical, stderr)
    else
        local output = fn.execute(cmd)
        output = vim.split(output, "\n")
        api.nvim_buf_set_lines(bufnr, -2, -1, true, output)
    end
end

command("Redir", redir, {
    nargs = "+",
    complete = "command",
    bang = true,
    range = true,
})

command("Mess", function()
    vim.cmd([[Redir messages]])
end, { bar = true })
