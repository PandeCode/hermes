return {
	{
		"none-ls.nvim",
		after = function()
			local null_ls = require("null-ls")

			local problems = {
				{ pattern = "\226\128\139", name = "ZERO WIDTH SPACE", replacement = "" }, -- ​ (U+200B)
				{ pattern = "\194\160", name = "NON-BREAKING SPACE", replacement = " " }, --   (U+00A0)
				{ pattern = "\239\187\191", name = "BYTE ORDER MARK", replacement = "" }, -- ﻿ (U+FEFF)
				{ pattern = "\226\128\141", name = "ZERO WIDTH JOINER", replacement = "" }, -- ‍ (U+200D)
				{ pattern = "\226\128\142", name = "RIGHT-TO-LEFT MARK", replacement = "" }, -- ‎ (U+200E)
				{ pattern = "\226\128\143", name = "LEFT-TO-RIGHT MARK", replacement = "" }, -- ‏ (U+200F)
			}

			local no_problems = {
				method = null_ls.methods.DIAGNOSTICS,
				filetypes = { "*" },
				generator = {
					fn = function(params)
						local diagnostics = {}

						for i, line in ipairs(params.content) do
							for _, problem in ipairs(problems) do
								local col, end_col = line:find(problem.pattern)
								if col and end_col then
									table.insert(diagnostics, {
										row = i,
										col = col,
										end_col = end_col + 1,
										source = "no-problems",
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

			-- Setup null-ls
			null_ls.setup({
				sources = {
					-- Formatting
					null_ls.builtins.formatting.stylua,
					null_ls.builtins.formatting.gofmt,
					null_ls.builtins.formatting.black,
					null_ls.builtins.formatting.isort,
					null_ls.builtins.formatting.alejandra,
					null_ls.builtins.formatting.nixfmt,
					null_ls.builtins.formatting.clang_format,
					null_ls.builtins.formatting.typstyle,
					null_ls.builtins.formatting.just,
					null_ls.builtins.formatting.gdformat,
					null_ls.builtins.formatting.dart_format,
					null_ls.builtins.formatting.prettierd,
					null_ls.builtins.formatting.cmake_format,

					null_ls.builtins.diagnostics.gdlint,

					null_ls.builtins.diagnostics.glslc.with({
						extra_args = { "--target-env=opengl" }, -- use opengl instead of vulkan1.0
					}),

					null_ls.builtins.diagnostics.qmllint,

					null_ls.builtins.diagnostics.vale,
					null_ls.builtins.diagnostics.markdownlint,
					null_ls.builtins.diagnostics.checkmake,
					null_ls.builtins.diagnostics.cmake_lint,

					null_ls.builtins.diagnostics.statix,
					null_ls.builtins.diagnostics.deadnix,

					null_ls.builtins.diagnostics.fish,

					null_ls.builtins.hover.dictionary,
					null_ls.builtins.hover.printenv,

					null_ls.builtins.completion.spell,

					null_ls.builtins.code_actions.statix,
					null_ls.builtins.code_actions.ts_node_action,
				},
			})

			null_ls.register(no_problems)

			-- LSP formatting fallback
			local function lsp_format_with_fallback(opts)
				vim.lsp.buf.format({
					bufnr = opts.bufnr,
					async = opts.async or false,
					timeout_ms = opts.timeout_ms or 1000,
				})
			end

			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = "*",
				callback = function()
					lsp_format_with_fallback({ timeout_ms = 500 })
				end,
			})

			vim.keymap.set({ "n", "v" }, "<leader>cf", function()
				lsp_format_with_fallback({ timeout_ms = 1000 })
			end, { desc = "[C]ode [F]ormat" })

			local nmap = function(keys, func, desc)
				if desc then
					desc = "LSP: " .. desc
				end

				vim.keymap.set("n", keys, func, { desc = desc })
			end

			nmap("gr", function()
				require("snacks").picker.lsp_references()
			end, "[G]oto [R]eferences")
			nmap("gI", function()
				require("snacks").picker.lsp_implementations()
			end, "[G]oto [I]mplementation")
			nmap("<leader>ds", function()
				require("snacks").picker.lsp_symbols()
			end, "[D]ocument [S]ymbols")
			nmap("<leader>ws", function()
				require("snacks").picker.lsp_workspace_symbols()
			end, "[W]orkspace [S]ymbols")

			local noice = require("noice.lsp")

			vim.lsp.inlay_hint.enable(true)

			nmap("K", noice.hover, "Hover Documentation")
			nmap("<C-k>", noice.signature, "Signature Documentation")

			nmap("<leader>d", vim.lsp.buf.type_definition, "Type [D]efinition")

			nmap("<space>cl", vim.lsp.codelens.run, "[C]ode [L]ens")
			nmap("<F2>", vim.lsp.buf.rename, "[R]e[n]ame")
			nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
			nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
			nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
			nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
			nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
			nmap("<leader>wl", function()
				print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
			end, "[W]orkspace [L]ist Folders")
		end,
	},
}
