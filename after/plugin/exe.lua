-- TODO add a just startup eval mode like org
local tbl = {
	{ "s", "xargs -I '{}' python3 -c \"from sympy import simplify; print(simplify('{}'))\"" },
	{ "n", "xargs -I '{}' numbat -e '{}'" },
	{ "k", "kalker" },
	{ "p", "python3" },
}

local function run_command_on_text(cmd, mode)
	local selected_text = ""
	if mode == "v" then
		selected_text = GetVisualSelection()
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
		vim.cmd('silent normal! gv"_d')
		vim.api.nvim_put({ selected_text, output_str }, "c", false, true)
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
