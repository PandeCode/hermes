local catUtils = require("nixCatsUtils")
if catUtils.isNixCats and nixCats("lspDebugMode") then
    vim.lsp.set_log_level("debug")
end

-- NOTE: This file uses lzextras.lsp handler https://github.com/BirdeeHub/lzextras?tab=readme-ov-file#lsp-handler
-- This is a slightly more performant fallback function
-- for when you don't provide a filetype to trigger on yourself.
-- nixCats gives us the paths, which is faster than searching the rtp!
local old_ft_fallback = require("lze").h.lsp.get_ft_fallback()
require("lze").h.lsp.set_ft_fallback(function(name)
    local lspcfg = nixCats.pawsible({ "allPlugins", "opt", "nvim-lspconfig" })
        or nixCats.pawsible({ "allPlugins", "start", "nvim-lspconfig" })
    if lspcfg then
        local ok, cfg = pcall(dofile, lspcfg .. "/lsp/" .. name .. ".lua")
        if not ok then
            ok, cfg = pcall(dofile, lspcfg .. "/lua/lspconfig/configs/" .. name .. ".lua")
        end
        return (ok and cfg or {}).filetypes or {}
    else
        return old_ft_fallback(name)
    end
end)

vim.keymap.set("n", "<leader>gd", function()
    Snacks.picker.diagnostics()
end, { desc = "[G]o [D]iagnostic" })

require("lze").load({

    {
        "nvim-lspconfig",
        on_require = { "lspconfig" },
        -- NOTE: define a function for lsp,
        -- and it will run for all specs with type(plugin.lsp) == table
        -- when their filetype trigger loads them
        lsp = function(plugin)
            vim.lsp.config(plugin.name, plugin.lsp or {})
            vim.lsp.enable(plugin.name)
        end,
        before = function(_)
            vim.lsp.config("*", { on_attach = require("lsps.on_attach") })
        end,
    },

    { import = "lsps.none_ls" },
    { import = "lsps.clangd" },
    { import = "lsps.lua_ls" },
    { import = "lsps.python" },
    { import = "lsps.haskell" },
    { import = "lsps.nixd" },
    { "gopls",                lsp = {} },

    {
        -- lazydev makes your lsp way better in your config without needing extra lsp configuration.
        "lazydev.nvim",
        cmd = { "LazyDev" },
        ft = "lua",
        after = function(_)
            require("lazydev").setup({
                library = {
                    { words = { "nixCats" }, path = (nixCats.nixCatsPath or "") .. "/lua" },
                },
            })
        end,
    },

    {
        "typescript-tools.nvim",
        on_plugin = { "nvim-lspconfig", "plenary.nvim" },
        ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
        after = function()
            require("typescript-tools").setup({})
        end,
    },
    {
        "mason.nvim",
        enabled = not catUtils.isNixCats,
        on_plugin = { "nvim-lspconfig" },
        load = function(name)
            vim.cmd.packadd(name)
            vim.cmd.packadd("mason-lspconfig.nvim")
            require("mason").setup()
            -- auto install will make it install servers when lspconfig is called on them.
            require("mason-lspconfig").setup({ automatic_installation = true })
        end,
    },
})
