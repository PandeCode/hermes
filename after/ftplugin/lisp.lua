if vim.b.did_after_ftplugin_lisp then
	return
end
vim.b.did_after_ftplugin_lisp = true

local endswith = function(str, suffix)
	return str:sub(- #suffix) == suffix
end

function sbclIsRunning()
	local ps = io.popen("pidof sbcl")
	local pids = ps:read()
	ps:close()

	if pids then
		pids = vim.fn.split(pids, " ")
		for _, pid in ipairs(pids) do
			local _, args = pcall(vim.fn.readfile, "/proc/" .. pid .. "/cmdline")
			if _ then
				if endswith(args[1], "start-vlime.lisp\n") then
					return pid
				end
			end
		end
	end

	return false
end

require("lze").load({
	{
		"parinfer-rust",
		allow_again = false,
		after = function()
			vim.keymap.set("n", "<leader>pf", function()
				vim.cmd(":ParinferOff<cr>")
				vim.notify("ParinferOff")
			end, { silent = true, noremap = true, desc = "ParinferOff" })
			vim.keymap.set("n", "<leader>pn", function()
				vim.cmd(":ParinferOn<cr>")
				vim.notify("ParinferOn")
			end, { silent = true, noremap = true, desc = "ParinferOn" })
		end,
	},
	{
		"vlime",
		allow_again = false,
		after = function()
			local on_std = function(_, data, _)
				if data then
					vim.notify("Vlime:\n" .. table.concat(data, "\n"))
				end
			end

			vim.keymap.set("n", "<leader>ss", function()
				vim.fn.jobstart({ "killall", "-9", "sbcl" })
			end)

			vim.keymap.set("n", "<leader>ss", function()
				local pid = sbclIsRunning()
				if pid then
					vim.notify("Vlime:\nAlready running at: " .. pid)
					return
				end
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
						vim.notify("Vlime: Process exited with code " .. code)
					end,
				})
				vim.notify("Vlime: Server started")
			end, { noremap = true })
		end,
	},
})
