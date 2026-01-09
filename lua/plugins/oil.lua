vim.g.loaded_netrwPlugin = 1

require("oil").setup({
	default_file_explorer = true,
	view_options = {
		show_hidden = true,
	},
	columns = {
		"icon",
		"permissions",
		"size",
		-- "mtime",
	},
	keymaps = {
		["g?"] = "actions.show_help",
		["<CR>"] = "actions.select",
		["<C-s>"] = "actions.select_vsplit",
		["<C-h>"] = "actions.select_split",
		["<C-t>"] = "actions.select_tab",
		["<C-p>"] = "actions.preview",
		["<C-c>"] = "actions.close",
		["<C-l>"] = "actions.refresh",
		["-"] = "actions.parent",
		["_"] = "actions.open_cwd",
		["`"] = "actions.cd",
		["~"] = "actions.tcd",
		["gs"] = "actions.change_sort",
		["gx"] = "actions.open_external",
		["g."] = "actions.toggle_hidden",
		["g\\"] = "actions.toggle_trash",
	},
})
vim.keymap.set("n", "-", "<cmd>Oil<CR>", { noremap = true, desc = "Open Parent Directory" })
vim.keymap.set("n", "<leader>-", "<cmd>Oil .<CR>", { noremap = true, desc = "Open nvim root directory" })

local matchAny = require("utils").matchAny

local matchAny = require("utils").matchAny

local handlers = {
	{
		{
			"%.jpe?g$",
			"%.png$",
			"%.webp$",
			"%.bmp$",
			"%.tiff?$",
			"%.avif$",
		},
		{ "feh" },
	},

	{
		{ "%.gif$" },
		{ "mpv",   "--loop-file=inf" },
	},

	{
		{ "%.pdf$", "%.epub$", "%.djvu$" },
		{ "zathura" },
	},

	{
		{
			"%.mp4$",
			"%.mkv$",
			"%.webm$",
			"%.mov$",
			"%.avi$",
		},
		{ "mpv" },
	},

	{
		{
			"%.mp3$",
			"%.flac$",
			"%.wav$",
			"%.ogg$",
			"%.m4a$",
		},
		{ "mpv", "--no-video" },
	},

	{
		{
			"%.obj$",
			"%.fbx$",
			"%.gltf$",
			"%.glb$",
			"%.stl$",
			"%.ply$",
			"%.dae$",
			"%.3ds$",
		},
		{ "f3d" },
	},

	{
		{
			"%.docx$",
			"%.xlsx$",
			"%.pptx$",
			"%.odt$",
			"%.ods$",
			"%.odp$",
		},
		{ "onlyoffice-desktopeditors" },
	},

	{
		{
			"%.ttf$",
			"%.otf$",
			"%.woff2?$",
		},
		{ "fontforge" },
	},
}

local function open_external(name, dir)
	local path = dir .. name

	for _, h in ipairs(handlers) do
		local pattern = h[1]
		local fn = h[2]
		if matchAny(name, pattern) then
			local cmd = vim.deepcopy(fn)
			table.insert(cmd, path)
			vim.fn.jobstart(cmd, { detach = true })
			return true
		end
	end

	return false
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = "oil",
	callback = function(ev)
		local oil = require("oil")

		vim.keymap.set("n", "<CR>", function()
			local entry = oil.get_cursor_entry()
			local dir = oil.get_current_dir()
			if not entry or entry.type ~= "file" or not dir or not open_external(entry.name, dir) then
				oil.select()
				return
			end
		end, { buffer = ev.buf, silent = true })
	end,
})
