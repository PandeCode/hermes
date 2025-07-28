local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

return {
	{
		"neocmake",
		lsp = {
			-- server_capabilities = { hoverProvider = false },
			on_attach = function(_, bufrn)
				require("lsps.on_attach")(bufrn)
			end,
			capabilities = capabilities,
		},
	},
}
