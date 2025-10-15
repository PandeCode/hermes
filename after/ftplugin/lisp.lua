if vim.b.did_after_ftplugin_python then
	return
end
vim.b.did_after_ftplugin_python = true

require("lze").load({
	{
		"parinfer-rust",
		allow_again = false,
		after = function()
			vim.keymap.set("n", "<leader>po", ":ParinferOff<cr>", { silent = true, noremap = true })
			vim.keymap.set("n", "<leader>pn", ":ParinferOn<cr>", { silent = true, noremap = true })
		end,
	},
	{
		"vlime",
		allow_again = false,
		after = function()
			local on_std = function(_, data, _)
				if data then
					vim.notify(table.concat(data, "\n"))
				end
			end

			vim.keymap.set("n", "<leader>ss", function()
				vim.fn.jobstart({
					"sbcl",
					"--load",
					(nixCats.extra("vlimePath") or "") .. "/lisp/start-vlime.lisp",
				}, {
					detach = true,
					stdout_buffered = true,
					stderr_buffered = true,
					on_stdout = on_std,
					on_stderr = on_std,
					on_exit = function(_, code, _)
						_VLIME_RUNNING = false
						vim.notify("Vlime: Process exited with code " .. code)
					end,
				})
				vim.notify("Vlime: Server started")
			end, { noremap = true })
		end,
	},
})
