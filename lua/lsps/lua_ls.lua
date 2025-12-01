local libs = vim.iter(vim.split(package.path, ";"))
	:map(function(k)
		return vim.split(k, "?")[1]
	end)
	:totable()

vim.list_extend(libs, {
	vim.fn.getenv("VIMRUNTIME"),
	unpack(vim.api.nvim_get_runtime_file("", true)),
	(function()
		if nixCats and nixCats.nixCatsPath then
			return nixCats.nixCatsPath .. "/lua"
		end
	end)(),
})

local emmylua_json = {
	["$schema"] =
	"https://raw.githubusercontent.com/EmmyLuaLs/emmylua-analyzer-rust/refs/heads/main/crates/emmylua_code_analysis/resources/schema.json",
	runtime = { version = "LuaJIT" },
	diagnostics = {
		globals = { "nixCats", "vim" },
		disable = { "missing-fields", "undefined-global" },
		enables = { "undefined-field" },
		severity = {
			["undefined-global"] = "warning",
			unused = "hint",
		},
	},
	resource = {
		paths = { "?.lua", "?/init.lua" },
	},

	workspace = {
		library = libs,
		workspaceRoots = { "lua" },
		ignoreDir = { "build", "dist", "node_modules" },
		ignoreGlobs = { "*.log", "*.tmp", "test_*" },
	},
}

function rewriteEmmyLuaJson()
	vim.fn.writefile(vim.fn.split(vim.fn.json_encode(emmylua_json), "\n"), ".emmyrc.json")
end

function rewriteEmmyLuaJsonExit()
	rewriteEmmyLuaJson()
	vim.cmd("q!")
end

return {
	{
		"emmylua_ls",
		lsp = {
			on_attach = function(_, bufrn)
				require("lsps.on_attach")(_, bufrn)
			end,
		},
	},
}
