-- from reddit
local track = "·"
local handle = "━━"

local scrollpeek = function()
	local lines = vim.api.nvim_buf_line_count(0)
	-- disabled if the file has less lines
	if lines < 300 then
		return
	end
	-- or vim.o.columns - 20 for full width
	local width = 40
	local factor = vim.fn.line("w0") / lines
	local left = math.floor(factor * width)
	local right = width - left
	local str = track:rep(left) .. handle .. track:rep(right)
	-- print() pollutes :messages but this doesn't
	-- vim.print(str)
	vim.cmd('echo "' .. str .. '"')
end

vim.keymap.set("n", "<C-f>", function()
	vim.cmd([[execute "normal! \<C-f>"]])
	scrollpeek()
end)

vim.keymap.set("n", "<C-b>", function()
	vim.cmd([[execute "normal! \<C-b>"]])
	scrollpeek()
end)
