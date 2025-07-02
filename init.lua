vim.loader.enable()
math.randomseed(os.time())

require("nixCatsUtils").setup({
	non_nix_value = true,
})

require("utils")

function _G.catRequire(path)
	if path ~= nil and nixCats(path) then
		return require(path)
	end
end

function _G.fnSetup(path, opts)
	return function()
		require(path).setup(opts or {})
	end
end

require("general")

require("non_nix_download")

require("plugins")
require("lsps")

catRequire("go")
catRequire("rust")
catRequire("web")
catRequire("debug")
