vim.loader.enable()

require("nixCatsUtils").setup({
	non_nix_value = true,
})

require("utils")

math.randomseed(os.time())

require("general")

require("non_nix_download")

require("plugins")
require("lsps")

-- require("go")
-- require("rust")
require("web")
require("debug")

require("fire")
