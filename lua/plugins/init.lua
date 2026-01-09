require("lze").register_handlers({
	spec_field = "setup",
	set_lazy = false,
	modify = function(plugin)
		plugin.after = function()
			if
				type(plugin.setup) == "table"
				and type(plugin.setup[1]) == "string"
				and type(plugin.setup) == "table"
			then
				require(plugin.setup[1]).setup(plugin.setup[2])
			elseif type(plugin.setup) == "string" then
				require(plugin.setup).setup({})
			end
		end
		return plugin
	end,
})

require("lze").register_handlers(require("nixCatsUtils.lzUtils").for_cat)
require("lze").register_handlers(require("lzextras").lsp)

require("plugins.oil")

require("lze").load({
	{ "cord.nvim" },
	{ "vim-wakatime" },
	{ "dropbar.nvim" },
	{ "neoscroll.nvim",             setup = "neoscroll" },
	{ "fidget.nvim",                event = "DeferredUIEnter", setup = "fidget" },

	-- { import = "plugins.hover" },

	{ import = "plugins.mini" },
	{ import = "plugins.snacks" },
	{ import = "plugins.bufferline" },
	{ import = "plugins.lualine" },

	{ import = "plugins.treesitter" },
	{ import = "plugins.completion" },
	{ import = "plugins.git" },

	{
		"refactoring.nvim",
		ft = {
			"typescript",
			"typescriptreact",
			"c",
			"cpp",
			"rust",
		},
		after = function()
			vim.keymap.set({ "n", "x" }, "<leader>rr", function()
				require("refactoring").select_refactor()
			end)

			-- You can also use below = true here to to change the position of the printf
			-- statement (or set two remaps for either one). This remap must be made in normal mode.
			vim.keymap.set("n", "<leader>rp", function()
				require("refactoring").debug.printf({ below = false })
			end)

			-- Print var

			vim.keymap.set({ "x", "n" }, "<leader>rv", function()
				require("refactoring").debug.print_var()
			end)
			-- Supports both visual and normal mode

			vim.keymap.set("n", "<leader>rc", function()
				require("refactoring").debug.cleanup({})
			end)
			-- Supports only normal mode
		end,
	},

	{
		"overseer.nvim",
		setup = {
			"overseer",
			task_list = {
				direction = "bottom",
				min_height = 25,
				max_height = 25,
				default_detail = 1,
			},
		},
	},

	{ "nui.nvim", dep_of = "noice.nvim" },
	{
		"noice.nvim",
		after = function()
			require("noice").setup({
				notify = { enabled = false },
				lsp = {
					override = {
						["vim.lsp.util.convert_input_to_markdown_lines"] = true,
						["vim.lsp.util.stylize_markdown"] = true,
					},
				},
				presets = {
					bottom_search = false, -- use a classic bottom cmdline for search
					command_palette = true, -- position the cmdline and popupmenu together
					long_message_to_split = true, -- long messages will be sent to a split
					lsp_doc_border = true, -- add a border to hover docs and signature help
				},
			})
		end,
	},

	{
		"markdown-preview.nvim",
		cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
		ft = "markdown",
		keys = {
			{
				"<leader>mp",
				"<cmd>MarkdownPreview <CR>",
				mode = { "n" },
				noremap = true,
				desc = "markdown preview",
			},
			{
				"<leader>ms",
				"<cmd>MarkdownPreviewStop <CR>",
				mode = { "n" },
				noremap = true,
				desc = "markdown preview stop",
			},
			{
				"<leader>mt",
				"<cmd>MarkdownPreviewToggle <CR>",
				mode = { "n" },
				noremap = true,
				desc = "markdown preview toggle",
			},
		},
		before = function(plugin)
			vim.g.mkdp_auto_close = 0
		end,
	},

	{
		"undotree",
		cmd = { "UndotreeToggle", "UndotreeHide", "UndotreeShow", "UndotreeFocus", "UndotreePersistUndo" },
		keys = { { "<leader>U", "<cmd>UndotreeToggle<CR>", mode = { "n" }, desc = "Undo Tree" } },
		before = function(_)
			vim.g.undotree_WindowLayout = 1
			vim.g.undotree_SplitWidth = 40
		end,
	},

	{
		"vim-startuptime",
		cmd = { "StartupTime" },
		before = function(_)
			vim.g.startuptime_event_width = 0
			vim.g.startuptime_tries = 10
			vim.g.startuptime_exe_path = nixCats.packageBinPath
		end,
	},
})
