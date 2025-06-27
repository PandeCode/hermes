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
	{
		"overseer.nvim",
		ft = { "go", "cpp", "python", "c" },
		after = function()
			require("overseer").setup({
				templates = { "builtin", "user.shell", "user.run_script", "user.cpp_build" },
			})

			vim.api.nvim_create_user_command("WatchRun", function()
				local overseer = require("overseer")
				overseer.run_template({ name = "run script" }, function(task)
					if task then
						task:add_component({ "restart_on_save", paths = { vim.fn.expand("%:p") } })
						local main_win = vim.api.nvim_get_current_win()
						overseer.run_action(task, "open vsplit")
						vim.api.nvim_set_current_win(main_win)
					else
						vim.notify("WatchRun not supported for filetype " .. vim.bo.filetype, vim.log.levels.ERROR)
					end
				end)
			end, {})

			vim.api.nvim_create_user_command("OverseerRestartLast", function()
				local overseer = require("overseer")
				local tasks = overseer.list_tasks({ recent_first = true })
				if vim.tbl_isempty(tasks) then
					vim.notify("No tasks found", vim.log.levels.WARN)
				else
					overseer.run_action(tasks[1], "restart")
				end
			end, {})

			vim.api.nvim_create_user_command("Make", function(params)
				-- Insert args at the '$*' in the makeprg
				local cmd, num_subs = vim.o.makeprg:gsub("%$%*", params.args)
				if num_subs == 0 then
					cmd = cmd .. " " .. params.args
				end
				local task = require("overseer").new_task({
					cmd = vim.fn.expandcmd(cmd),
					components = {
						{ "on_output_quickfix", open = not params.bang, open_height = 8 },
						"default",
					},
				})
				task:start()
			end, {
				desc = "Run your makeprg as an Overseer task",
				nargs = "*",
				bang = true,
			})

			vim.keymap.set("n", "<leader>or", ":OverseerRun<CR>", { noremap = true, silent = true })
			vim.keymap.set("n", "<leader>ow", ":WatchRun<CR>", { noremap = true, silent = true })
			vim.keymap.set("n", "<leader>ol", ":OverseerRestartLast<CR>", { noremap = true, silent = true })
			vim.keymap.set("n", "<leader>om", ":Make<CR>", { noremap = true, silent = true })
		end,
	},

	{ import = "plugins.mini" },
	{ import = "plugins.snacks" },
	{ import = "plugins.bufferline" },
	{ import = "plugins.lualine" },

	{ import = "plugins.treesitter" },
	{ import = "plugins.completion" },

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
					bottom_search = true, -- use a classic bottom cmdline for search
					command_palette = true, -- position the cmdline and popupmenu together
					long_message_to_split = true, -- long messages will be sent to a split
					lsp_doc_border = false, -- add a border to hover docs and signature help
				},
			})
		end,
	},
	{
		"conform.nvim",
		for_cat = "general",
		keys = { { "<leader>cf" } },
		after = function()
			local conform = require("conform")

			conform.setup({
				formatters_by_ft = {
					lua = { "stylua" },
					go = { "gofmt", "golint" },
					templ = { "templ" },
					python = { "isort", "black" }, -- Conform will run multiple formatters sequentially
					javascript = { { "prettierd", "prettier" } }, -- Use a sub-list to run only the first available formatter
					nix = { "alejandra", "nixfmt" },
					c = { "clang-format" },
					cpp = { "clang-format" },
				},
				format_on_save = {
					-- These options will be passed to conform.format()
					timeout_ms = 500,
					lsp_format = "fallback",
				},
			})

			vim.keymap.set({ "n", "v" }, "<leader>cf", function()
				conform.format({
					lsp_fallback = true,
					async = false,
					timeout_ms = 1000,
				})
			end, { desc = "[C]ode [F]ormat" })
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

	{
		"gitsigns.nvim",
		for_cat = "general.always",
		event = "DeferredUIEnter",
		after = function(plugin)
			require("gitsigns").setup({
				-- See `:help gitsigns.txt`
				signs = {
					add = { text = "+" },
					change = { text = "~" },
					delete = { text = "_" },
					topdelete = { text = "‾" },
					changedelete = { text = "~" },
				},
				on_attach = function(bufnr)
					local gs = package.loaded.gitsigns

					local function map(mode, l, r, opts)
						opts = opts or {}
						opts.buffer = bufnr
						vim.keymap.set(mode, l, r, opts)
					end

					-- Navigation
					map({ "n", "v" }, "]c", function()
						if vim.wo.diff then
							return "]c"
						end
						vim.schedule(function()
							gs.next_hunk()
						end)
						return "<Ignore>"
					end, { expr = true, desc = "Jump to next hunk" })

					map({ "n", "v" }, "[c", function()
						if vim.wo.diff then
							return "[c"
						end
						vim.schedule(function()
							gs.prev_hunk()
						end)
						return "<Ignore>"
					end, { expr = true, desc = "Jump to previous hunk" })

					-- Actions
					-- visual mode
					map("v", "<leader>hs", function()
						gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end, { desc = "stage git hunk" })
					map("v", "<leader>hr", function()
						gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end, { desc = "reset git hunk" })
					-- normal mode
					map("n", "<leader>gs", gs.stage_hunk, { desc = "git stage hunk" })
					map("n", "<leader>gr", gs.reset_hunk, { desc = "git reset hunk" })
					map("n", "<leader>gS", gs.stage_buffer, { desc = "git Stage buffer" })
					map("n", "<leader>gu", gs.undo_stage_hunk, { desc = "undo stage hunk" })
					map("n", "<leader>gR", gs.reset_buffer, { desc = "git Reset buffer" })
					map("n", "<leader>gp", gs.preview_hunk, { desc = "preview git hunk" })
					map("n", "<leader>gb", function()
						gs.blame_line({ full = false })
					end, { desc = "git blame line" })
					map("n", "<leader>gd", gs.diffthis, { desc = "git diff against index" })
					map("n", "<leader>gD", function()
						gs.diffthis("~")
					end, { desc = "git diff against last commit" })

					-- Toggles
					map("n", "<leader>gtb", gs.toggle_current_line_blame, { desc = "toggle git blame line" })
					map("n", "<leader>gtd", gs.toggle_deleted, { desc = "toggle git show deleted" })

					-- Text object
					map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "select git hunk" })
				end,
			})
			vim.cmd([[hi GitSignsAdd guifg=#04de21]])
			vim.cmd([[hi GitSignsChange guifg=#83fce6]])
			vim.cmd([[hi GitSignsDelete guifg=#fa2525]])
		end,
	},
})
