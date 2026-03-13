vim.lsp.enable("fennel_ls")

null_ls = require("null-ls")
null_ls.register(null_ls.builtins.formatting.fnlfmt)

vim.keymap.set("n", "<leader>ts", function()
	vim.treesitter.start()
end)

vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "init.fnl",
	callback = function()
		local input = vim.fn.expand("%:p")
		local output = vim.fn.expand("%:p:r") .. ".lua"

		vim.fn.jobstart({ "fennel", "--compile", input }, {
			stdout_buffered = true,
			stderr_buffered = true,

			on_stdout = function(_, data)
				if data and #data > 0 then
					vim.fn.writefile(data, output)
				end
			end,

			on_stderr = function(_, data)
				if data and data[1] ~= "" then
					vim.notify(table.concat(data, "\n"), vim.log.levels.ERROR)
				end
			end,

			on_exit = function(_, code)
				if code == 0 then
					vim.notify("Fennel compiled → init.lua")
				end
			end,
		})
	end,
})

-- switch fnl lua file
vim.keymap.set("n", "<leader>gh", function()
	local cwd = vim.fn.getcwd()
	local lua_dir = cwd .. "/lua"
	local fnl_dir = cwd .. "/fnl"
	local dir_len = #lua_dir
	local cur_file = vim.fn.expand("%:p:r")

	if cur_file:find("^" .. lua_dir) then
		local final = fnl_dir .. cur_file:sub(dir_len + 1) .. ".fnl"
		vim.notify(final)
		vim.cmd.edit(final)
	elseif cur_file:find("^" .. fnl_dir) then
		local final = lua_dir .. cur_file:sub(dir_len + 1) .. ".lua"
		vim.notify(final)
		vim.cmd.edit(final)
	else
		vim.notify("Not in dir")
	end
end)

-- switch eval selected
vim.keymap.set("n", "<leader>ev", function()
	local f = loadstring("return " .. vim.fn.getreg('"')) or function()
		return "None"
	end
	vim.notify(vim.inspect(f()))
end)

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "<filetype>" },
	callback = function()
		vim.treesitter.start()
	end,
})

vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.wo[0][0].foldmethod = "manual"

vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
