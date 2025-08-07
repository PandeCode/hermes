vim.cmd([[
if argc() > 1
	silent blast " load last buffer
	silent bfirst " switch back to the first
endif

if exists('+termguicolors')
	let &t_8f="\<Esc>[38;2;%lu;%lu;%lum"
	let &t_8b="\<Esc>[48;2;%lu;%lu;%lum"
	set termguicolors
endif

syntax sync minlines=256

" Allow saving of files as sudo when I forgot to start vim using sudo.
cnoremap w!! execute 'write !sudo tee % >/dev/null' <bar> edit!
]])

vim.api.nvim_create_user_command("Gitadd", function()
	local filename = vim.fn.expand("%")
	vim.cmd("!git add %")
	vim.notify("Git added '" .. filename .. "'")
end, {})

vim.api.nvim_create_user_command("Chmodx", function()
	local filename = vim.fn.expand("%")
	vim.cmd("!chmod +x %")
	vim.notify("Given execution rights to '" .. filename .. "'")
end, {})

vim.api.nvim_create_user_command("Rmf", function()
	vim.cmd("!rm -f %")
end, {})

vim.cmd([[
  cnoreabbrev W w
  cnoreabbrev Q q
  cnoreabbrev WQ wq
  cnoreabbrev Wq wq
  cnoreabbrev WQA wqa
  cnoreabbrev Wqa wqa
  cnoreabbrev QA qa
  cnoreabbrev Qa qa
  cnoreabbrev E e
  cnoreabbrev gitadd Gitadd
  cnoreabbrev chmodx Chmodx
  cnoreabbrev rmf Rmf
]])

vim.opt.number = true
vim.opt.relativenumber = true

vim.api.nvim_create_autocmd("InsertEnter", {
	pattern = "*",
	callback = function()
		vim.opt.relativenumber = false
	end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
	pattern = "*",
	callback = function()
		vim.opt.relativenumber = true
	end,
})

-- Make parent folders if they don't exist
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	pattern = "*",
	callback = function()
		vim.fn.mkdir(vim.fn.expand("<afile>:p:h"), "p")
	end,
})

local function set_filetype(pattern, filetype)
	vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
		pattern = pattern,
		callback = function()
			vim.o.filetype = filetype
		end,
	})
end

set_filetype("*/xmobarrc", "haskell")
set_filetype({ "*.ls", "*.v" }, "vlang")
set_filetype("*.yuck", "yuck")
set_filetype("*.keys", "keys")
set_filetype({ "*.shader", "*.frag", "*.vert" }, "glsl")
set_filetype({ "*.json", "*/waybar/config" }, "jsonc")
set_filetype("*/hypr/**/*.conf", "hypr")
set_filetype("*/sway/*.conf", "swayconfig")

-- https://nvchad.com/docs/recipes/

-- This autocmd will restore cursor position on file open
vim.api.nvim_create_autocmd("BufReadPost", {
	pattern = "*",
	callback = function()
		local line = vim.fn.line("'\"")
		if
			line > 1
			and line <= vim.fn.line("$")
			and vim.bo.filetype ~= "commit"
			and vim.fn.index({ "xxd", "gitrebase" }, vim.bo.filetype) == -1
		then
			vim.cmd('normal! g`"')
		end
	end,
})

-- This is a WSL specific setting to use the Windows clipboard for + and * registers
if vim.fn.filereadable("/proc/sys/fs/binfmt_misc/WSLInterop") == 1 then
	vim.g.clipboard = {
		name = "WslClipboard",
		copy = {
			["+"] = "clip.exe",
			["*"] = "clip.exe",
		},
		paste = {
			["+"] = 'pwsh.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
			["*"] = 'pwsh.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
		},
		cache_enabled = 0,
	}
end

-- A per project shadafile
-- https://www.reddit.com/r/neovim/comments/1hkpgar/a_per_project_shadafile/
vim.opt.shadafile = (function()
	local data = vim.fn.stdpath("data")

	local cwd = vim.fn.getcwd()
	cwd = vim.fs.root(cwd, ".git") or cwd

	local cwd_b64 = vim.base64.encode(cwd)

	local file = vim.fs.joinpath(data, "project_shada", cwd_b64)
	vim.fn.mkdir(vim.fs.dirname(file), "p")

	return file
end)()

vim.api.nvim_create_autocmd("TextYankPost", {
	callback = vim.highlight.on_yank,
})
