-- TODO:
-- home row '$' '^'
-- vim.keymap.set("n", "[<Space>", [[<CMD>put!=repeat(nr2char(10), v:count1)<BAR>']+1<CR>]])
-- vim.keymap.set("n", "]<Space>", [[<CMD>put =repeat(nr2char(10), v:count1)<BAR>'[-1<CR>]])
-- keymap for diagnostic set quickfix
-- revisit keymap and leverage <leader> key
-- keymap for other lsp gr?
-- keymap for system clipboard yank/paste
-- plugins list:
--- picker
--- neorg
--- harpoon
--- multicursor (for alignment)
--- lsp progress (statusline widget or fidget?)
--- statusline
--- git (perhaps mini.git)
--- leap.nvim
--- linter
--- dadbod dbui
--- diffview
--- quickfix?
--- dap.nvim (debugger)
--- search n replace (grug-far?)
--- firenvim

local api, fn, lsp, opt = vim.api, vim.fn, vim.lsp, vim.opt
local augroup = api.nvim_create_augroup
local autocmd = api.nvim_create_autocmd
local map = vim.keymap.set

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_python3_provider = 0

augroup("core", { clear = true })

-- bootstrap lazy.nvim
local lazy_path = table.concat({ fn.stdpath("data"), "/lazy/lazy.nvim" })
if not vim.uv.fs_stat(lazy_path) then
    vim.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable",
        "https://github.com/folke/lazy.nvim.git",
        lazy_path,
    }):wait()
end
opt.rtp:prepend(lazy_path)

----------
-- options
----------
opt.completeopt = { "menu", "menuone", "noselect" }
opt.confirm = true
opt.exrc = true -- automatically execute .nvim.lua
opt.hlsearch = false
opt.isfname:append("@-@") -- treat '@' as part of file name
opt.jumpoptions:append("stack,view")
opt.laststatus = 3 -- global statusline
opt.mousemodel = "extend" -- right click extends selection
opt.number = true
opt.pumheight = 5
opt.relativenumber = true
opt.shada = { "'10", "<0", "s10", "h", "/10", "r/tmp" }
opt.shiftround = true -- indent by N * vim.o.shiftwidth
opt.showmode = false
opt.signcolumn = "yes:1"
opt.termguicolors = true
opt.undofile = true
opt.virtualedit = "block" -- allow to extend cursors to void text area
opt.wildcharm = (""):byte() --  to trigger completion on cmdline mapping
opt.wildignore:append("*/__pycache/*,*/node_modules/*")
opt.wildoptions:remove("pum") -- disable popup menu, use list in statusline
opt.wrap = false

opt.shortmess:append({
    I = true, -- hide default startup screen
    A = true, -- ignore swap warning message
    c = true, -- disable completion message
    a = true, -- shorter message format
})

opt.list = true
opt.listchars = {
    nbsp = "⦸",     -- U+29B8
    extends = "→",  -- U+2192
    precedes = "←", -- U+2190
    tab = "▹ ",     -- U+25B9
    trail = "·",    -- U+00B7
}
vim.opt.fillchars = {
    foldclose = "▶", -- U+25B6
    foldopen = "▼", -- U+25BC
}

opt.diffopt:append({
    "algorithm:histogram",
    "indent-heuristic",
    "linematch:60",
})

-- better scroll
opt.scrolloff = 6
opt.sidescroll = 6
opt.sidescrolloff = 6

-- transparent popup
opt.pumblend = 10
opt.winblend = 10

-- persistent window splits
opt.splitbelow = true
opt.splitright = true

-- better search n replace behaviour
opt.ignorecase = true -- \C to disable case-insensitive behaviour
opt.inccommand = "split" -- show preview of replace command
opt.smartcase = true

if vim.fn.executable("rg") == 1 then
    opt.grepprg = "rg --no-heading --smart-case --vimgrep"
    opt.grepformat = {
        "%f:%l:%c:%m",
        "%f:%l:%m",
    }
end

-- ftplugin may include 'o' option
autocmd("FileType", {
    group = "core",
    callback = function()
        opt.formatoptions:remove("o")
    end,
})

vim.diagnostic.config({
    severity_sort = true,
    jump = {
        float = true,
    },
})

---------------
-- autocommands
---------------
autocmd("TextYankPost", {
    group = "core",
    callback = function()
        vim.highlight.on_yank({ timeout = 69 })
    end,
})

autocmd("BufReadPost", {
    group = "core",
    callback = function()
        local exclude = { "gitcommit", "gitrebase", "help" }
        if vim.tbl_contains(exclude, vim.bo.ft) then
            return
        end

        -- restore last cursor location
        local m = api.nvim_buf_get_mark(0, '"')
        if m[1] > 0 and m[1] <= api.nvim_buf_line_count(0) then
            pcall(api.nvim_win_set_cursor, 0, m)
        end
    end,
})

autocmd("BufNewFile", {
    group = "core",
    callback = function()
        autocmd("BufWritePre", {
            group = "core",
            buffer = 0,
            once = true,
            callback = function(ev)
                -- ignore uri pattern
                if ev.match:match([[^%w+://]]) then
                    return
                end

                local f = vim.uv.fs_realpath(ev.match) or ev.match
                fn.mkdir(fn.fnamemodify(f, ":p:h"), "p")
            end,
        })
    end,
})

----------
-- keymaps
----------
-- center current search result
map("n", "n", "nzz")
map("n", "N", "Nzz")
map("n", "*", "*zz")
map("n", "#", "#zz")

-- join line without moving cursors
map("n", "J", "mzJ`z")
map("n", "gJ", "mzgJ`z")

-- shift lines without exiting visual line
map("x", "<", "<gv")
map("x", ">", ">gv")

-- window resize with count
map("n", "<m-,>", "<c-w>5<")
map("n", "<m-.>", "<c-w>5>")
map("n", "<m-=>", "<c-w>+")
map("n", "<m-->", "<c-w>-")

-- https://github.com/mhinz/vim-galore#saner-command-line-history
local cmd_hist = function(direction)
    return function()
        local wildmode = fn.wildmenumode()
        if direction > 0 then
            return wildmode == 1 and [[<c-n>]] or [[<down>]]
        else
            return wildmode == 1 and [[<c-p>]] or [[<up>]]
        end
    end
end
map("c", "<c-p>", cmd_hist(-1), { expr = true })
map("c", "<c-n>", cmd_hist(1), { expr = true })

-- quick exit
autocmd("FileType", {
    group = "core",
    pattern = {
        "checkhealth",
        "qf",
        "help",
    },
    callback = function()
        map("n", "q", "<cmd>bd<cr>", {
            buffer = 0,
            nowait = true,
        })
    end,
})

------
-- lsp
------
lsp.log.set_level(lsp.log.levels.ERROR)
lsp.log.set_format_func(vim.inspect)
autocmd("LspAttach", {
    group = "core",
    callback = function(ev)
        local buf = ev.buf
        local id = ev.data.client_id
        local handlers, with = lsp.handlers, lsp.with

        handlers["textDocument/signatureHelp"] = with(
            handlers.signature_help, {
                anchor_bias = "above",
            })
        handlers["textDocument/hover"] = with(
            handlers.hover, {
                anchor_bias = "above",
            })
    end,
})

-- TODO: support function for cmd
-- https://github.com/ms-jpq/lua-async-await
local lsp_start = function(buf, opts)
    local cap = lsp.protocol.make_client_capabilities()
    local cmp_cap = require("cmp_nvim_lsp").default_capabilities()
    opts.capabilities = vim.tbl_deep_extend("force", cap, cmp_cap)

    opts.markers = opts.markers or {}
    opts.markers[#opts.markers + 1] = ".git"
    opts.root_dir = vim.fs.root(buf, opts.markers)

    lsp.start(opts)
end

local lsp_add = function(name, opts)
    if opts.enabled == false then
        return
    end

    opts.name = name
    autocmd("FileType", {
        group = "core",
        pattern = opts.filetypes,
        callback = function(ev)
            local buf = ev.buf
            if vim.bo[buf].buftype == "nofile" then
                return
            end
            lsp_start(buf, opts)
        end,
    })
end

lsp_add("dartls", {
    cmd = { "dart", "language-server", "--protocol=lsp" },
    filetypes = "dart",
    markers = { "pubspec.yaml" },
    init_options = {
        onlyAnalyzeProjectsWithOpenFiles = true,
        suggestFromUnimportedLibraries = true,
    },
    settings = {
        dart = {
            completeFunctionCalls = true,
            showTodos = false,
        },
    },
})

----------
-- plugins
----------
local spec = {
    {
        "rebelot/kanagawa.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("kanagawa").setup({
                theme = "dragon",
                background = { dark = "dragon" },
                compile = true,
                transparent = true,

                overrides = function(C)
                    local T = C.theme
                    local P = C.palette

                    return {
                        -- dark completion menu
                        Pmenu = {
                            fg = T.ui.shade0,
                            bg = T.ui.bg_p1,
                            blend = vim.o.pumblend,
                        },
                        PmenuSel = { fg = "NONE", bg = T.ui.bg_p2 },
                        PmenuSbar = { bg = T.ui.bg_m1 },
                        PmenuThumb = { bg = T.ui.bg_p2 },

                        Boolean = { bold = false },
                    }
                end,
            })

            vim.cmd.colorscheme("kanagawa")
        end,
    },
    {
        "stevearc/oil.nvim",
        lazy = false,
        config = function()
            map("n", "-", "<cmd>Oil<cr>")

            require("oil").setup({
                view_options = {
                    show_hidden = true,
                    is_always_hidden = function(name, bufnr)
                        return name == ".."
                    end
                },
            })
        end,
    },
    {
        "mbbill/undotree",
        keys = {
            { "you", vim.cmd.UndotreeToggle, mode = "n" },
        },
        init = function()
            vim.g.undotree_HelpLine = 0
            vim.g.undotree_SetFocusWhenToggle = 1
            vim.g.undotree_ShortIndicators = 1
        end,
    },
    {
        "hrsh7th/nvim-cmp",
        version = false,
        event = "InsertEnter",
        cmd = { "CmpStatus" },
        dependencies = {
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-nvim-lsp",
        },
        config = function()
            local cmp = require("cmp")
            local mapping = cmp.mapping

            cmp.setup({
                completion = {
                    keyword_length = 2,
                },
                snippet = {
                    expand = function(args)
                        vim.snippet.expand(args.body)
                    end,
                },
                mapping = mapping.preset.insert({
                    ["<c-e>"] = mapping.abort(),
                    ["<c-y>"] = mapping.confirm({ select = true }),
                    ["<cr>"] = mapping.confirm({ select = false }),
                    ["<c-u>"] = mapping.scroll_docs(-5),
                    ["<c-d>"] = mapping.scroll_docs(5),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                }, {
                    { name = "path" },
                    {
                        name = "buffer",
                        keyword_length = 4,
                        option = {
                            get_bufnrs = function()
                                local bufs = api.nvim_list_bufs()

                                local bufnrs = {}
                                local j = 1
                                for i = 1, #bufs do
                                    local buf = bufs[i]
                                    local bt = vim.bo[buf].buftype
                                    local loaded = api.nvim_buf_is_loaded(buf)

                                    if loaded and bt ~= "nofile" and bt ~= "prompt" then
                                        local loc = api.nvim_buf_line_count(buf)
                                        local size = api.nvim_buf_get_offset(buf, loc)
                                        -- only source buffer with size below 1MB
                                        if size <= 1048576 then
                                            bufnrs[j] = buf
                                            j = j + 1
                                        end
                                    end
                                end

                                return bufnrs
                            end
                        },
                    },
                }),
                experimental = {
                    ghost_text = true,
                },
            })
        end,
    },
    {
        "stevearc/conform.nvim",
        lazy = true,
        cmd = { "ConformInfo" },
        init = function()
            opt.formatexpr = [[v:lua.require("conform").formatexpr()]]
        end,
        opts = {
            formatters_by_ft = {
                ["_"] = { "trim_whitespace" },
            },
            log_level = vim.log.levels.ERROR,
        },
    },
}

vim.cmd.packadd("cfilter")
require("lazy").setup({
    spec = spec,
    checker = { enabled = false },
    change_detection = { notify = false },
    performance = {
        rtp = {
            disabled_plugins = {
                "tutor",
                "rplugin",
                "gzip",
                "tarPlugin",
                "zipPlugin",
                "spellfile",
                "netrwPlugin",
            },
        },
    },
})
