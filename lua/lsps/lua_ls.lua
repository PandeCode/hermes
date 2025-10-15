return {
	{
		"emmylua_ls",
		lsp = {
			on_attach = function(_, bufrn)
				require("lsps.on_attach")(_, bufrn)
			end,
			settings = {
				Lua = {
					runtime = { version = "LuaJIT" },
					workspace = {
						library = {
							unpack(vim.api.nvim_get_runtime_file("", true)),
							{ words = { "nixCats" }, path = (nixCats.nixCatsPath or "") .. "/lua" },
						},
						diagnostics = {
							globals = { "nixCats", "vim" },
							disable = { "missing-fields" },
						},
					},
				},
			},
		},
	},
}
