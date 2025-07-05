local catUtils = require("nixCatsUtils")

local nix_lsp = vim.fn.getenv("CPP_NIX_LSP")
if nix_lsp == vim.NIL or nix_lsp == nil or nix_lsp == "" then
	nix_lsp = "nixd"
end

if nix_lsp == "nil_ls" then
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
				on_attach = require("lsps.on_attach"),
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
