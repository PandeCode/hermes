require("lze").register_handlers({
	spec_field = "on_setup",
	set_lazy = false,
	modify = function(plugin)
		plugin.after = function()
			if
				type(plugin.on_setup) == "table"
				and type(plugin.on_setup[1]) == "string"
				and type(plugin.on_setup) == "table"
			then
				require(plugin.on_setup[1]).setup(plugin.on_setup[2])
			elseif type(plugin.on_setup) == "string" then
				require(plugin.on_setup).setup({})
			end
		end
		return plugin
	end,
})
require("lze").register_handlers(require("nixCatsUtils.lzUtils").for_cat)
require("lze").register_handlers(require("lzextras").lsp)

require("plugins.oil")

require("lze").load({
	{ "vim-wakatime" },

	{ "neoscroll.nvim", on_setup = "neoscroll" },
	{ import = "plugins.mini" },
	{ import = "plugins.snacks" },
	{ import = "plugins.bufferline" },
	{ import = "plugins.lualine" },

	{ import = "plugins.treesitter" },
	{ import = "plugins.completion" },
	{ import = "plugins.git" },
	{ import = "plugins.ai" },

	{ "dropbar.nvim" },

	-- {
	-- 	"hover.nvim",
	--        enabled = false,
	-- 	after = function()
	-- 		require("hover").setup({
	-- 			init = function()
	-- 				require("hover.providers.lsp")
	-- 				require("hover.providers.diagnostic")
	-- 				require("hover.providers.gh")
	-- 				require("hover.providers.gh_user")
	-- 				require("hover.providers.dap")
	-- 				require("hover.providers.fold_preview")
	-- 				require("hover.providers.man")
	-- 				require("hover.providers.dictionary")
	--
	-- 				require("hover").register({
	-- 					name = "Tailwind",
	-- 					priority = 1,
	-- 					enabled = function(bufnr)
	-- 						if "lua" == vim.fn.getbufvar(bufnr, "&filetype") then
	-- 							return true
	-- 						end
	-- 						return false
	-- 					end,
	-- 					execute = function(opts, done)
	-- 						local cword = vim.fn.expand("<cword>")
	--
	-- 						local base_descriptions = {
	-- 							base00 = {
	-- 								"Primary Background – Darkest Layer",
	-- 								"Forms the foundation for the entire UI background.",
	-- 								"Often used for editor background or root containers.",
	-- 							},
	-- 							base01 = {
	-- 								"Secondary Background – Elevated Shade",
	-- 								"Provides subtle contrast against the base background.",
	-- 								"Used for panels, sidebars, or secondary surfaces.",
	-- 							},
	-- 							base02 = {
	-- 								"Selection Highlight Background",
	-- 								"Indicates selected items or active highlights.",
	-- 								"Balances visibility without overpowering text.",
	-- 							},
	-- 							base03 = {
	-- 								"Comments and Inactive Elements",
	-- 								"Applies to comments, invisible characters, or guide lines.",
	-- 								"Lower visual priority, often gray or muted.",
	-- 							},
	-- 							base04 = {
	-- 								"Muted Foreground – Secondary Text",
	-- 								"Used for non-essential or auxiliary text.",
	-- 								"Labels, placeholders, or subdued notes.",
	-- 							},
	-- 							base05 = {
	-- 								"Primary Foreground – Main Text",
	-- 								"Default color for regular readable text.",
	-- 								"Applies to most content, code, and UI labels.",
	-- 							},
	-- 							base06 = {
	-- 								"Bright Foreground – Highlight Text",
	-- 								"Used for strong emphasis or important UI elements.",
	-- 								"Often applied to active items or headings.",
	-- 							},
	-- 							base07 = {
	-- 								"Light Background – Emphasized UI Areas",
	-- 								"Brightest shade in the theme.",
	-- 								"Typically used for inline code blocks or selected backgrounds.",
	-- 							},
	-- 							base08 = {
	-- 								"Critical Elements – Errors & Variables",
	-- 								"Marks error messages, exceptions, and mutable variables.",
	-- 								"Stands out for immediate attention.",
	-- 							},
	-- 							base09 = {
	-- 								"Numeric & Boolean Values",
	-- 								"Highlights numeric constants, booleans, and enums.",
	-- 								"Useful for distinguishing fixed values in code.",
	-- 							},
	-- 							base0A = {
	-- 								"Structural Elements – Classes & Tags",
	-- 								"Emphasizes class names, markup tags, and data types.",
	-- 								"Defines the skeleton of code structures.",
	-- 							},
	-- 							base0B = {
	-- 								"Literals & Strings",
	-- 								"Used for string values and quoted literals.",
	-- 								"Reflects static data in code.",
	-- 							},
	-- 							base0C = {
	-- 								"Support Constructs – RegEx & Helpers",
	-- 								"Marks auxiliary patterns, regex, and helper keywords.",
	-- 								"Often associated with tools and diagnostics.",
	-- 							},
	-- 							base0D = {
	-- 								"Executable Elements – Functions & Methods",
	-- 								"Represents callable code units: functions, methods, and lambdas.",
	-- 								"Essential for understanding logic flow.",
	-- 							},
	-- 							base0E = {
	-- 								"Language Keywords & Control Flow",
	-- 								"Identifies language-level reserved words and flow-control terms.",
	-- 								"For example: `if`, `else`, `return`, `while`.",
	-- 							},
	-- 							base0F = {
	-- 								"Deprecated or Legacy Components",
	-- 								"Highlights outdated code, unstable APIs, or transitional elements.",
	-- 								"Useful for signaling migration or refactor needs.",
	-- 							},
	-- 						}
	--
	-- 						for key, description in pairs(base_descriptions) do
	-- 							if string.find(cword, key) then
	-- 								done({ lines = description, filetype = "markdown" })
	-- 							end
	-- 						end
	-- 					end,
	-- 				})
	-- 			end,
	-- 			preview_opts = {
	-- 				border = "single",
	-- 			},
	-- 			-- Whether the contents of a currently open hover window should be moved
	-- 			-- to a :h preview-window when pressing the hover keymap.
	-- 			preview_window = false,
	-- 			title = true,
	-- 			mouse_providers = {
	-- 				"LSP",
	-- 			},
	-- 			mouse_delay = 50000,
	-- 		})
	--
	-- 		-- Setup keymaps
	-- 		vim.keymap.set("n", "K", require("hover").hover, { desc = "hover.nvim" })
	-- 		vim.keymap.set("n", "gK", require("hover").hover_select, { desc = "hover.nvim (select)" })
	-- 		vim.keymap.set("n", "<C-p>", function()
	-- 			require("hover").hover_switch("previous")
	-- 		end, { desc = "hover.nvim (previous source)" })
	-- 		vim.keymap.set("n", "<C-n>", function()
	-- 			require("hover").hover_switch("next")
	-- 		end, { desc = "hover.nvim (next source)" })
	--
	-- 		-- Mouse support
	-- 		vim.keymap.set("n", "<MouseMove>", require("hover").hover_mouse, { desc = "hover.nvim (mouse)" })
	-- 		vim.o.mousemoveevent = true
	-- 	end,
	-- },

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
		for_cat = "general.markdown",
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
	{
		"fidget.nvim",
		event = "DeferredUIEnter",
		-- keys = "",
		after = function(plugin)
			require("fidget").setup({})
		end,
	},
})
