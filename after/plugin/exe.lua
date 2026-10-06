-- TODO add a just startup eval mode like org
local tbl = {
	{ "s", "xargs -I '{}' python3 -c \"from sympy import simplify; print(simplify('{}'))\"" },
	{ "n", "xargs -I '{}' numbat -e '{}'" },
	{ "k", "kalker" },
	{ "p", "python3" },
}

local function run_command_on_text(cmd, mode)
	local selected_text = ""
	local first, last, vmode
	if mode == "v" then
		-- leave visual mode so '< and '> hold this selection
		vim.cmd("normal! \27")
		first, last, vmode = vim.fn.getpos("'<"), vim.fn.getpos("'>"), vim.fn.visualmode()
		selected_text = table.concat(vim.fn.getregion(first, last, { type = vmode }), "\n")
	else
		selected_text = vim.api.nvim_get_current_line()
	end

	vim.print(selected_text)

	local output = vim.fn.systemlist(cmd, selected_text)
	if vim.v.shell_error ~= 0 then
		vim.notify("Command failed with exit code: " .. vim.v.shell_error, vim.log.levels.ERROR)
		return
	end
	local output_str = table.concat(output, "\n")

	if mode == "v" then
		-- the selection is replaced by itself and the output on the next line
		local lines = vim.split(selected_text .. "\n" .. output_str, "\n")
		if vmode == "V" then
			vim.api.nvim_buf_set_lines(0, first[2] - 1, last[2], false, lines)
		else
			local last_line = vim.fn.getline(last[2])
			local end_col = math.min(last[3], #last_line)
			end_col = end_col + vim.str_utf_end(last_line, end_col)
			vim.api.nvim_buf_set_text(0, first[2] - 1, first[3] - 1, last[2] - 1, end_col, lines)
		end
	else
		vim.api.nvim_set_current_line(selected_text .. " = " .. output_str)
	end
end

for _, v in ipairs(tbl) do
	vim.keymap.set("n", "<leader>e" .. v[1], function()
		run_command_on_text(v[2], "n")
	end, { silent = true, desc = v[3] or v[2] })
	vim.keymap.set("v", "<leader>e" .. v[1], function()
		run_command_on_text(v[2], "v")
	end, { silent = true, desc = v[3] or v[2] })
end
