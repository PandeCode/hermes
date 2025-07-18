return {
	{
		"hls",
		lsp = {
			-- server_capabilities = { hoverProvider = false },
			on_attach = function(args)
				require("lsps.on_attach")()
			end,
		},
	},
}
