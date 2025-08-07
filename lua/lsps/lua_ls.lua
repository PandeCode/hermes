local lua_lsp = vim.fn.getenv("LUA_LSP")

if lua_lsp == vim.NIL or lua_lsp == nil or lua_lsp == "" then
	lua_lsp = "lua"
end

if lua_lsp == "emmy" then
	return {
		{
			"emmylua_ls",
			lsp = {
				on_attach = function(_, bufrn)
					require("lsps.on_attach")(_, bufrn)
				end,
				-- settings = {
				-- 	Lua = {
				-- 		runtime = { version = "LuaJIT" },
				-- 		formatters = {
				-- 			ignoreComments = true,
				-- 		},
				-- 		signatureHelp = { enabled = true },
				-- 		diagnostics = {
				-- 			globals = { "nixCats", "vim" },
				-- 			disable = { "missing-fields" },
				-- 		},
				-- 		telemetry = { enabled = false },
				-- 	},
				-- },
			},
		},
	}
else
	return {
		{
			"lua_ls",
			lsp = {
				on_attach = function(_, bufrn)
					require("lsps.on_attach")(_, bufrn)
				end,
				settings = {
					Lua = {
						runtime = { version = "LuaJIT" },
						formatters = {
							ignoreComments = true,
						},
						signatureHelp = { enabled = true },
						diagnostics = {
							globals = { "nixCats", "vim" },
							disable = { "missing-fields" },
						},
						telemetry = { enabled = false },
					},
				},
			},
		},
	}
end
