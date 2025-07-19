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
