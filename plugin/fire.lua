if vim.g.started_by_firenvim ~= true then
	return
end

-- an opt plugin, the browser runs nvim -c "call firenvim#run()"
vim.cmd.packadd("firenvim")

vim.o.cmdheight = 0
vim.o.tabline = ""
vim.o.showtabline = 0
vim.o.statusline = ""
vim.o.laststatus = 0
