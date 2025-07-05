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
		"none-ls.nvim",
		after = function()
			local null_ls = require("null-ls")

			null_ls.setup({
				sources = {
					null_ls.builtins.code_actions.proselint,
					null_ls.builtins.completion.spell,
					null_ls.builtins.diagnostics.codespell,
					null_ls.builtins.diagnostics.markdownlint,
					null_ls.builtins.diagnostics.statix,
					null_ls.builtins.code_actions.statix,
				},
			})

			local problems = {
				{ pattern = "\226\128\139", name = "ZERO WIDTH SPACE", replacement = "" },
				{ pattern = "\194\160", name = "NON-BREAKING SPACE", replacement = " " },
				{ pattern = "\239\187\191", name = "BYTE ORDER MARK", replacement = "" },
				{ pattern = "\226\128\141", name = "ZERO WIDTH JOINER", replacement = "" },
				{ pattern = "\226\128\142", name = "RIGHT-TO-LEFT MARK", replacement = "" },
				{ pattern = "\226\128\143", name = "LEFT-TO-RIGHT MARK", replacement = "" },
			}

			local no_problems = {
				method = null_ls.methods.DIAGNOSTICS,
				filetypes = { "*" },
				generator = {
					fn = function(params)
						local diagnostics = {}

						for i, line in ipairs(params.content) do
							for _, problem in ipairs(problems) do
								local col, end_col = line:find(problem)
								if col and end_col then
									table.insert(diagnostics, {
										row = i,
										col = col,
										end_col = end_col + 1,
										source = "no-really",
										message = problem.name,
										severity = vim.diagnostic.severity.WARN,
									})
								end
							end
						end
						return diagnostics
					end,
				},
			}

			null_ls.register(no_problems)
		end,
		lazy = true,
	},

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

	{ import = "lsps.clangd" },
	{ import = "lsps.lua_ls" },
	{ import = "lsps.nixd" },
	{ "gopls", for_cat = "go", lsp = {} },

	{
		-- lazydev makes your lsp way better in your config without needing extra lsp configuration.
		"lazydev.nvim",
		for_cat = "neonixdev",
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
		for_cat = "web",
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
