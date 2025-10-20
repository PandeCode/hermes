local libs = { unpack(vim.api.nvim_get_runtime_file("", true)), (nixCats.nixCatsPath or "") .. "/lua" }

local emmylua_json = {
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
		paths = libs,
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
