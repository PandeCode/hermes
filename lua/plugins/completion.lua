local load_w_after = function(name)
	vim.cmd.packadd(name)
	vim.cmd.packadd(name .. "/after")
end

return {
	{
		"cmp-cmdline",
		on_plugin = { "blink.cmp" },
		load = load_w_after,
	},
	{
		"blink.compat",
		dep_of = { "cmp-cmdline" },
	},
	{
		"friendly_snippets",
		on_plugin = "luasnip",
	},
	{
		"luasnip",
		dep_of = { "blink.cmp" },
		after = function(_)
			local luasnip = require("luasnip")
			require("luasnip.loaders.from_vscode").load()
			luasnip.config.setup({})

			local ls = require("luasnip")

			vim.keymap.set({ "i", "s" }, "<M-n>", function()
				if ls.choice_active() then
					ls.change_choice(1)
				end
			end)
		end,
	},
	{
		"colorful-menu.nvim",
		dep_of = { "blink.cmp" },
	},
	{
		"blink.cmp",
		event = "DeferredUIEnter",
		after = function(_)
			require("blink.cmp").setup({
				-- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
				-- See :h blink-cmp-config-keymap for configuring keymaps
				keymap = {
					preset = "default",
				},
				cmdline = {
					enabled = true,
					completion = {
						menu = {
							auto_show = true,
						},
					},
					sources = function()
						local type = vim.fn.getcmdtype()
						-- Search forward and backward
						if type == "/" or type == "?" then
							return { "buffer" }
						end
						-- Commands
						if type == ":" or type == "@" then
							-- return { "cmdline", "cmp_cmdline" }
							return { "cmdline" }
						end
						return {}
					end,
				},
				fuzzy = {
					implementation = "prefer_rust_with_warning",
					sorts = {
						"exact",
						-- defaults
						"score",
						"sort_text",
					},
				},
				signature = {
					enabled = true,
					window = {
						show_documentation = true,
					},
				},
				completion = {
					menu = {
						draw = {
							treesitter = { "lsp" },
							-- columns = { { "kind_icon" }, { "label", gap = 1 }, { "kind" } },
							columns = { { "kind_icon" }, { "label", "label_description", gap = 1 }, { "kind" } },

							components = {
								kind_icon = {
									text = function(ctx)
										local kind_icon, _, _ = require("mini.icons").get("lsp", ctx.kind)
										return kind_icon
									end,
									highlight = function(ctx)
										local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
										return hl
									end,
								},
								kind = {
									highlight = function(ctx)
										local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
										return hl
									end,
								},
							},

							-- components = {
							-- 	label = {
							-- 		width = { fill = true, max = 60 },
							-- 		text = function(ctx)
							-- 			local highlights_info = require("colorful-menu").blink_highlights(ctx)
							-- 			if highlights_info ~= nil then
							-- 				-- Or you want to add more item to label
							-- 				return highlights_info.label
							-- 			else
							-- 				return ctx.label
							-- 			end
							-- 		end,
							-- 		highlight = function(ctx)
							-- 			local highlights = {}
							-- 			local highlights_info = require("colorful-menu").blink_highlights(ctx)
							-- 			if highlights_info ~= nil then
							-- 				highlights = highlights_info.highlights
							-- 			end
							-- 			for _, idx in ipairs(ctx.label_matched_indices) do
							-- 				table.insert(highlights, { idx, idx + 1, group = "BlinkCmpLabelMatch" })
							-- 			end
							-- 			-- Do something else
							-- 			return highlights
							-- 		end,
							-- 	},
							-- },
							-- components = {
							--   label = {
							--     text = function(ctx)
							--       return require("colorful-menu").blink_components_text(ctx)
							--     end,
							--     highlight = function(ctx)
							--       return require("colorful-menu").blink_components_highlight(ctx)
							--     end,
							--   },
							-- },
						},
					},
					documentation = {
						auto_show = true,
					},
				},
				snippets = {
					preset = "luasnip",
				},
				sources = {
					default = {
						"lsp",
						"path",
						"snippets",
						"buffer",
						"omni",
					},
					per_filetype = {
						codecompanion = { "codecompanion" },
					},
					providers = {
						path = {
							score_offset = 50,
						},
						lsp = {
							score_offset = 40,
						},
						snippets = {
							score_offset = 40,
						},
						cmp_cmdline = {
							name = "cmp_cmdline",
							module = "blink.compat.source",
							score_offset = -100,
							opts = {
								cmp_name = "cmdline",
							},
						},
					},
				},
			})
		end,
	},
}
