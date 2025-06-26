vim.loader.enable()

require("nixCatsUtils").setup({
	non_nix_value = true,
})

require("general")

require("non_nix_download")

require("plugins")
require("lsps")

local function catRequire(path)
	if path ~= nil and nixCats(path) then
		return require(path)
	end
end

catRequire("go")
catRequire("rust")
catRequire("web")
catRequire("debug")
