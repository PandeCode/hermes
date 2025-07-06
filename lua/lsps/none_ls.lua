return {
    {
        "none-ls.nvim",
        after = function()
            local null_ls = require("null-ls")

            local problems = {
                { pattern = "\226\128\139", name = "ZERO WIDTH SPACE",   replacement = "" },  -- ​ (U+200B)
                { pattern = "\194\160",     name = "NON-BREAKING SPACE", replacement = " " }, --   (U+00A0)
                { pattern = "\239\187\191", name = "BYTE ORDER MARK",    replacement = "" },  -- ﻿ (U+FEFF)
                { pattern = "\226\128\141", name = "ZERO WIDTH JOINER",  replacement = "" },  -- ‍ (U+200D)
                { pattern = "\226\128\142", name = "RIGHT-TO-LEFT MARK", replacement = "" },  -- ‎ (U+200E)
                { pattern = "\226\128\143", name = "LEFT-TO-RIGHT MARK", replacement = "" },  -- ‏ (U+200F)
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

                    null_ls.builtins.formatting.prettierd,

                    -- Diagnostics / Code actions / Completion
                    null_ls.builtins.diagnostics.markdownlint,
                    null_ls.builtins.diagnostics.statix,
                    null_ls.builtins.code_actions.proselint,
                    null_ls.builtins.code_actions.statix,
                    null_ls.builtins.completion.spell,
                },
            })

            null_ls.register(no_problems)

            -- LSP formatting fallback
            local function lsp_format_with_fallback(opts)
                local clients = vim.lsp.get_active_clients({ bufnr = opts.bufnr or 0 })

                local has_lsp_formatter = vim.tbl_filter(function(client)
                    return client.supports_method("textDocument/formatting") and client.name ~= "null-ls"
                end, clients)

                vim.lsp.buf.format({
                    bufnr = opts.bufnr,
                    async = opts.async or false,
                    timeout_ms = opts.timeout_ms or 1000,
                    filter = function(client)
                        if not vim.tbl_isempty(has_lsp_formatter) then
                            return client.name ~= "null-ls"
                        end
                        return true
                    end,
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
        end,
    },
}
