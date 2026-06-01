local function replace_buffer_with_command(cmd)
	local file = vim.fn.expand("%:p")

	vim.bo.buftype = "nofile"
	vim.bo.bufhidden = "wipe"
	vim.bo.swapfile = false
	vim.bo.modifiable = true

	local full_cmd = cmd:gsub("%%", vim.fn.shellescape(file))
	local output = vim.fn.systemlist(full_cmd)

	vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
	vim.bo.modifiable = false
end

local function setup_filetype_view(extension, cmd)
	vim.api.nvim_create_autocmd("BufReadPost", {
		pattern = extension,
		callback = function()
			replace_buffer_with_command(cmd)
		end,
	})
end

setup_filetype_view(
	"*.so,*.so.2",
	"objdump --disassembler-color=extended-color --visualize-jumps=extended-color -M intel -T %"
)
setup_filetype_view("*.o,*.obj", "objdump --disassembler-color=extended-color -M intel -D %")
