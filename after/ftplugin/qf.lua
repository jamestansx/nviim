local api = vim.api

api.nvim_create_augroup("qf", { clear = true })
api.nvim_create_autocmd("BufEnter", {
    group = "qf",
    buffer = 0,
    nested = true,
    callback = function()
        if vim.fn.winnr("$") < 2 then
            vim.cmd([[silent quit]])
        end
    end,
})
