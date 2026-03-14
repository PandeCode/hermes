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
