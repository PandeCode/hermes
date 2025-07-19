local catUtils = require("nixCatsUtils")

local nix_lsp = vim.fn.getenv("NIX_LSP")

if nix_lsp ~= vim.NIL and nix_lsp ~= nil and nix_lsp == "nil" then
	return {
		{
			"nil_ls",
			lsp = {
				filetypes = { "nix" },
			},
		},
	}
else
	return {
		{
			"nixd",
			enabled = catUtils.isNixCats and (nixCats("nix") or nixCats("neonixdev")) or false,
			lsp = {
				filetypes = { "nix" },
				on_attach =
					function(_, bufrn)
						require("lsps.on_attach")(_, bufrn)
					end,
				settings = {
					nixd = {
						nixpkgs = {
							expr = nixCats.extra("nixdExtras.nixpkgs") or [[import <nixpkgs> {}]],
						},
						options = {
							nixos = {
								expr = nixCats.extra("nixdExtras.nixos_options"),
							},
							["home-manager"] = {
								expr = nixCats.extra("nixdExtras.home_manager_options"),
							},
						},
						formatting = {
							command = { "nixfmt" },
						},
						diagnostic = {
							suppress = {
								"sema-escaping-with",
							},
						},
					},
				},
			},
		},
	}
end
