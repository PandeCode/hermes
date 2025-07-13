return {
	{
		"hover.nvim",
		enabled = false,
		after = function()
			require("hover").setup({
				init = function()
					require("hover.providers.lsp")
					require("hover.providers.diagnostic")
					require("hover.providers.gh")
					require("hover.providers.gh_user")
					require("hover.providers.dap")
					require("hover.providers.fold_preview")
					require("hover.providers.man")
					require("hover.providers.dictionary")

					require("hover").register({
						name = "Tailwind",
						priority = 1,
						enabled = function(bufnr)
							if "lua" == vim.fn.getbufvar(bufnr, "&filetype") then
								return true
							end
							return false
						end,
						execute = function(opts, done)
							local cword = vim.fn.expand("<cword>")

							local base_descriptions = {
								base00 = {
									"Primary Background – Darkest Layer",
									"Forms the foundation for the entire UI background.",
									"Often used for editor background or root containers.",
								},
								base01 = {
									"Secondary Background – Elevated Shade",
									"Provides subtle contrast against the base background.",
									"Used for panels, sidebars, or secondary surfaces.",
								},
								base02 = {
									"Selection Highlight Background",
									"Indicates selected items or active highlights.",
									"Balances visibility without overpowering text.",
								},
								base03 = {
									"Comments and Inactive Elements",
									"Applies to comments, invisible characters, or guide lines.",
									"Lower visual priority, often gray or muted.",
								},
								base04 = {
									"Muted Foreground – Secondary Text",
									"Used for non-essential or auxiliary text.",
									"Labels, placeholders, or subdued notes.",
								},
								base05 = {
									"Primary Foreground – Main Text",
									"Default color for regular readable text.",
									"Applies to most content, code, and UI labels.",
								},
								base06 = {
									"Bright Foreground – Highlight Text",
									"Used for strong emphasis or important UI elements.",
									"Often applied to active items or headings.",
								},
								base07 = {
									"Light Background – Emphasized UI Areas",
									"Brightest shade in the theme.",
									"Typically used for inline code blocks or selected backgrounds.",
								},
								base08 = {
									"Critical Elements – Errors & Variables",
									"Marks error messages, exceptions, and mutable variables.",
									"Stands out for immediate attention.",
								},
								base09 = {
									"Numeric & Boolean Values",
									"Highlights numeric constants, booleans, and enums.",
									"Useful for distinguishing fixed values in code.",
								},
								base0A = {
									"Structural Elements – Classes & Tags",
									"Emphasizes class names, markup tags, and data types.",
									"Defines the skeleton of code structures.",
								},
								base0B = {
									"Literals & Strings",
									"Used for string values and quoted literals.",
									"Reflects static data in code.",
								},
								base0C = {
									"Support Constructs – RegEx & Helpers",
									"Marks auxiliary patterns, regex, and helper keywords.",
									"Often associated with tools and diagnostics.",
								},
								base0D = {
									"Executable Elements – Functions & Methods",
									"Represents callable code units: functions, methods, and lambdas.",
									"Essential for understanding logic flow.",
								},
								base0E = {
									"Language Keywords & Control Flow",
									"Identifies language-level reserved words and flow-control terms.",
									"For example: `if`, `else`, `return`, `while`.",
								},
								base0F = {
									"Deprecated or Legacy Components",
									"Highlights outdated code, unstable APIs, or transitional elements.",
									"Useful for signaling migration or refactor needs.",
								},
							}

							for key, description in pairs(base_descriptions) do
								if string.find(cword, key) then
									done({ lines = description, filetype = "markdown" })
								end
							end
						end,
					})
				end,
				preview_opts = {
					border = "single",
				},
				-- Whether the contents of a currently open hover window should be moved
				-- to a :h preview-window when pressing the hover keymap.
				preview_window = false,
				title = true,
				mouse_providers = {
					"LSP",
				},
				mouse_delay = 50000,
			})

			-- Setup keymaps
			vim.keymap.set("n", "K", require("hover").hover, { desc = "hover.nvim" })
			vim.keymap.set("n", "gK", require("hover").hover_select, { desc = "hover.nvim (select)" })
			vim.keymap.set("n", "<C-p>", function()
				require("hover").hover_switch("previous")
			end, { desc = "hover.nvim (previous source)" })
			vim.keymap.set("n", "<C-n>", function()
				require("hover").hover_switch("next")
			end, { desc = "hover.nvim (next source)" })

			-- Mouse support
			vim.keymap.set("n", "<MouseMove>", require("hover").hover_mouse, { desc = "hover.nvim (mouse)" })
			vim.o.mousemoveevent = true
		end,
	},
}
