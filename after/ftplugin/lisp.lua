_VLIME_RUNNING = false

if not _VLIME_RUNNING then
	require("lze").load({
		{ "parinfer-rust", allow_again = false },
		{ "vlime",         allow_again = false },
	})

	local on_std = function(_, data, _)
		if data then
			vim.notify(table.concat(data, "\n"))
		end
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
			_VLIME_RUNNING = false
			vim.notify("Process exited with code " .. code)
		end,
	})

	_VLIME_RUNNING = true
end
