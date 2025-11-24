local protected_dirs = {}
local protected_files = {}

function AddProtectedPattern(pattern)
	table.insert(protected_dirs, "^" .. pattern)
end

function AddProtectedFile(name)
	protected_files[name] = true
end

vim.api.nvim_create_autocmd("BufWritePre", {
	callback = function(args)
		local path = vim.api.nvim_buf_get_name(args.buf)
		if path == "" then
			return
		end

		local cwd = vim.loop.cwd() or ""
		local rel = path:gsub(cwd .. "/", "")
		local fname = vim.fn.fnamemodify(path, ":t")

		for _, pat in ipairs(protected_dirs) do
			if rel:match(pat) then
				vim.api.nvim_err_writeln("Write blocked: " .. rel)
				return true
			end
		end

		if protected_files[fname] then
			vim.api.nvim_err_writeln("Write blocked: " .. fname)
			return true
		end
	end,
})
