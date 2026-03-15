vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "*.fnl",
	callback = function()
		vim.fn.jobstart({ "./compile.sh" }, {
			stdout_buffered = true,
			stderr_buffered = true,
			on_stderr = function(_, data)
				if data and data[1] ~= "" then
					vim.notify(table.concat(data, "\n"), vim.log.levels.ERROR)
				end
			end,
			on_exit = function(_, code)
				if code == 0 then
					vim.notify("Fennel compiled")
				end
			end,
		})
	end,
})
