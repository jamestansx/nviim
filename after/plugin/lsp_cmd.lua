local api, lsp = vim.api, vim.lsp
local cmd = api.nvim_create_user_command

local lsp_client_complete = function()
    local cls = lsp.get_clients()

    local cl = {}
    for i = 1, #cls do
        cl[i] = cls[i].name
    end

    return cl
end

cmd("LspRestart", function(kwargs)
    local bufnr = api.nvim_get_current_buf()
    local name = kwargs.fargs[1]
    local cls = lsp.get_clients({ bufnr = bufnr, name = name })

    local detachs = {}
    for i = 1, #cls do
        local cl = cls[i]
        cl.stop(kwargs.bang)
        detachs[i] = { cl, lsp.get_buffers_by_client_id(cl.id) }
    end

    local timer = assert(vim.uv.new_timer())
    timer:start(500, 100, vim.schedule_wrap(function()
        for i = 1, #detachs do
            local cl = detachs[i][1]
            local bufs = detachs[i][2]

            if cl.is_stopped() then
                for j = 1, #bufs do
                    lsp.start(cl.config, { bufnr = bufs[j] })
                end
                detachs[i] = nil
            end
        end

        if next(detachs) == nil and not timer:is_closing() then
            timer:stop()
            timer:close()
        end
    end))
end, { nargs = "*", complete = lsp_client_complete, bang = true })

cmd("LspStop", function(kwargs)
    local bufnr = api.nvim_get_current_buf()
    local name = kwargs.fargs[1]
    local clients = lsp.get_clients({
        bufnr = bufnr,
        name = name,
    })

    for i = 1, #clients do
        clients[i].stop(kwargs.bang)
    end
end, { nargs = "*", complete = lsp_client_complete, bang = true })

cmd("LspInfo", function()
    vim.cmd([[botright checkhealth vim.lsp]])
end, {})

cmd("LspLog", function()
    vim.cmd(string.format("tabnew %s", lsp.get_log_path()))
end, {})
