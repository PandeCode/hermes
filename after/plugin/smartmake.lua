vim.keymap.set("n", "<leader>mk", function()
	vim.notify("running make")
	vim.cmd.make()
	vim.notify("finished make")
end, { noremap = true, silent = true })

-- if i dont see a cmakelists.txt, makefile, premake5.lua or justfile -- set makeprg=g++\ %\ -o\ %<
