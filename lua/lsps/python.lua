return {
	{
		"pyright",
		lsp = {
			-- server_capabilities = { hoverProvider = false },
			on_attach = function(_, bufrn)
				require("lsps.on_attach")(bufrn)
			end,
		},
	},
}
