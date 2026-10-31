-- khover: K on a piece of text runs a command on it and shows what comes
-- back in a float, as typst rendered to an image, a png, or markdown
-- a project registers a provider, from its .nvim.lua
-- this is supposed to be in my nvim config but there are other nvimmers out ther
--
--   require('khover').register({
--     filetype = 'zig',
--     query = '(string) @text',   -- tree-sitter query, captures @text
--     cmd = { '/path/to/tool' },  -- gets the text on stdin
--     kind = 'typst',             -- or 'png' (a path) or 'markdown'
--   })
--
-- images are drawn with vim.ui.img, which needs nvim 0.13 and a terminal
-- with the kitty graphics protocol. inside tmux they go through as kitty
-- unicode placeholders instead, see placeholders()

local M = {}

M.config = {
	typst = "typst",
	ppi = 150,
	-- the pixel size of a terminal cell, to size the float to the image
	-- NOTE: nvim can't ask the terminal for it yet, so this is a guess
	cell = { width = 10, height = 20 },
	max_width = 80,
	border = "rounded",
}

---@class khover.Provider
---@field filetype string
---@field query string tree-sitter query with a @text capture
---@field cmd string[] gets the text on stdin, prints the result
---@field kind 'typst'|'png'|'markdown'
---@field text? fun(s: string): string turns the captured text into the input
---@field cwd? string

---@type table<string, khover.Provider[]>
local providers = {}

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

local function map(buf)
	vim.keymap.set("n", "K", M.hover, { buffer = buf, desc = "khover" })
end

---@param p khover.Provider
function M.register(p)
	providers[p.filetype] = providers[p.filetype] or {}
	table.insert(providers[p.filetype], p)
	vim.api.nvim_create_autocmd("FileType", {
		pattern = p.filetype,
		callback = function(ev)
			map(ev.buf)
		end,
	})
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.bo[buf].filetype == p.filetype then
			map(buf)
		end
	end
end

-- the text of the provider's @text capture under the cursor
local function capture(buf, p)
	local ok, parser = pcall(vim.treesitter.get_parser, buf)
	if not ok or not parser then
		return nil
	end
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	row = row - 1
	parser:parse({ row, row + 1 })
	local query = vim.treesitter.query.parse(parser:lang(), p.query)
	for _, tree in ipairs(parser:trees()) do
		for id, node in query:iter_captures(tree:root(), buf, row, row + 1) do
			if query.captures[id] == "text" and vim.treesitter.is_in_node_range(node, row, col) then
				return vim.treesitter.get_node_text(node, buf)
			end
		end
	end
end

local function float(lines, filetype)
	return vim.lsp.util.open_floating_preview(lines, filetype, {
		border = M.config.border,
		focus_id = "khover",
		close_events = { "CursorMoved", "CursorMovedI", "InsertEnter", "BufLeave", "WinScrolled" },
	})
end

-- runs cmd with input on stdin and calls done with its stdout; a failure
-- shows its stderr in the float
local function run(cmd, input, cwd, done)
	local ok, err = pcall(vim.system, cmd, { stdin = input, cwd = cwd, text = true }, function(r)
		vim.schedule(function()
			if r.code ~= 0 then
				float(vim.split(r.stderr, "\n", { trimempty = true }), "")
			else
				done(r.stdout)
			end
		end)
	end)
	if not ok then
		vim.notify("khover: " .. err, vim.log.levels.WARN)
	end
end

local function be32(s, at)
	local a, b, c, d = s:byte(at, at + 3)
	return ((a * 256 + b) * 256 + c) * 256 + d
end

-- tmux drops images, and vim.ui.img places one at a screen position that
-- tmux knows nothing about. so in tmux the image is sent as passthrough as a
-- virtual placement, and the float holds kitty's unicode placeholders: text
-- cells tmux moves, clips and hides with the pane like any other, with the
-- image id in their fg color and the row and column in diacritics
-- NOTE: needs `set -g allow-passthrough on` in tmux and termguicolors
local placeholder = vim.fn.nr2char(0x10EEEE)

-- kitty's rowcolumn-diacritics.txt, the nth one means row or column n - 1
local diacritics = {
	0x0305,
	0x030D,
	0x030E,
	0x0310,
	0x0312,
	0x033D,
	0x033E,
	0x033F,
	0x0346,
	0x034A,
	0x034B,
	0x034C,
	0x0350,
	0x0351,
	0x0352,
	0x0357,
	0x035B,
	0x0363,
	0x0364,
	0x0365,
	0x0366,
	0x0367,
	0x0368,
	0x0369,
	0x036A,
	0x036B,
	0x036C,
	0x036D,
	0x036E,
	0x036F,
	0x0483,
	0x0484,
	0x0485,
	0x0486,
	0x0487,
	0x0592,
	0x0593,
	0x0594,
	0x0595,
	0x0597,
	0x0598,
	0x0599,
	0x059C,
	0x059D,
	0x059E,
	0x059F,
	0x05A0,
	0x05A1,
	0x05A8,
	0x05A9,
	0x05AB,
	0x05AC,
	0x05AF,
	0x05C4,
	0x0610,
	0x0611,
	0x0612,
	0x0613,
	0x0614,
	0x0615,
	0x0616,
	0x0617,
	0x0657,
	0x0658,
	0x0659,
	0x065A,
	0x065B,
	0x065D,
	0x065E,
	0x06D6,
	0x06D7,
	0x06D8,
	0x06D9,
	0x06DA,
	0x06DB,
	0x06DC,
	0x06DF,
	0x06E0,
	0x06E1,
	0x06E2,
	0x06E4,
	0x06E7,
	0x06E8,
	0x06EB,
	0x06EC,
	0x0730,
	0x0732,
	0x0733,
	0x0735,
	0x0736,
	0x073A,
	0x073D,
	0x073F,
	0x0740,
	0x0741,
	0x0743,
	0x0745,
	0x0747,
	0x0749,
	0x074A,
	0x07EB,
	0x07EC,
	0x07ED,
	0x07EE,
	0x07EF,
	0x07F0,
	0x07F1,
	0x07F3,
	0x0816,
	0x0817,
	0x0818,
	0x0819,
	0x081B,
	0x081C,
	0x081D,
	0x081E,
	0x081F,
	0x0820,
	0x0821,
	0x0822,
	0x0823,
	0x0825,
	0x0826,
	0x0827,
	0x0829,
	0x082A,
	0x082B,
	0x082C,
	0x082D,
	0x0951,
	0x0953,
	0x0954,
	0x0F82,
	0x0F83,
	0x0F86,
	0x0F87,
	0x135D,
	0x135E,
	0x135F,
	0x17DD,
	0x193A,
	0x1A17,
	0x1A75,
	0x1A76,
	0x1A77,
	0x1A78,
	0x1A79,
	0x1A7A,
	0x1A7B,
	0x1A7C,
	0x1B6B,
	0x1B6D,
	0x1B6E,
	0x1B6F,
	0x1B70,
	0x1B71,
	0x1B72,
	0x1B73,
	0x1CD0,
	0x1CD1,
	0x1CD2,
	0x1CDA,
	0x1CDB,
	0x1CE0,
	0x1DC0,
	0x1DC1,
	0x1DC3,
	0x1DC4,
	0x1DC5,
	0x1DC6,
	0x1DC7,
	0x1DC8,
	0x1DC9,
	0x1DCB,
	0x1DCC,
	0x1DD1,
	0x1DD2,
	0x1DD3,
	0x1DD4,
	0x1DD5,
	0x1DD6,
	0x1DD7,
	0x1DD8,
	0x1DD9,
	0x1DDA,
	0x1DDB,
	0x1DDC,
	0x1DDD,
	0x1DDE,
	0x1DDF,
	0x1DE0,
	0x1DE1,
	0x1DE2,
	0x1DE3,
	0x1DE4,
	0x1DE5,
	0x1DE6,
	0x1DFE,
	0x20D0,
	0x20D1,
	0x20D4,
	0x20D5,
	0x20D6,
	0x20D7,
	0x20DB,
	0x20DC,
	0x20E1,
	0x20E7,
	0x20E9,
	0x20F0,
	0x2CEF,
	0x2CF0,
	0x2CF1,
	0x2DE0,
	0x2DE1,
	0x2DE2,
	0x2DE3,
	0x2DE4,
	0x2DE5,
	0x2DE6,
	0x2DE7,
	0x2DE8,
	0x2DE9,
	0x2DEA,
	0x2DEB,
	0x2DEC,
	0x2DED,
	0x2DEE,
	0x2DEF,
	0x2DF0,
	0x2DF1,
	0x2DF2,
	0x2DF3,
	0x2DF4,
	0x2DF5,
	0x2DF6,
	0x2DF7,
	0x2DF8,
	0x2DF9,
	0x2DFA,
	0x2DFB,
	0x2DFC,
	0x2DFD,
	0x2DFE,
	0x2DFF,
	0xA66F,
	0xA67C,
	0xA67D,
	0xA6F0,
	0xA6F1,
	0xA8E0,
	0xA8E1,
	0xA8E2,
	0xA8E3,
	0xA8E4,
	0xA8E5,
	0xA8E6,
	0xA8E7,
	0xA8E8,
	0xA8E9,
	0xA8EA,
	0xA8EB,
	0xA8EC,
	0xA8ED,
	0xA8EE,
	0xA8EF,
	0xA8F0,
	0xA8F1,
	0xAAB0,
	0xAAB2,
	0xAAB3,
	0xAAB7,
	0xAAB8,
	0xAABE,
	0xAABF,
	0xAAC1,
	0xFE20,
	0xFE21,
	0xFE22,
	0xFE23,
	0xFE24,
	0xFE25,
	0xFE26,
	0x10A0F,
	0x10A38,
	0x1D185,
	0x1D186,
	0x1D187,
	0x1D188,
	0x1D189,
	0x1D1AA,
	0x1D1AB,
	0x1D1AC,
	0x1D1AD,
	0x1D242,
	0x1D243,
	0x1D244,
}

local ns = vim.api.nvim_create_namespace("khover")
local last_id = bit.band(vim.fn.getpid(), 0xffff) * 256

-- a kitty graphics command, wrapped so tmux hands it to the terminal as is
local function passthrough(control, payload)
	local fields = {}
	for k, v in pairs(control) do
		table.insert(fields, k .. "=" .. v)
	end
	local cmd = "\027_G" .. table.concat(fields, ",") .. (payload and ";" .. payload or "") .. "\027\\"
	vim.api.nvim_ui_send("\027Ptmux;" .. (cmd:gsub("\027", "\027\027")) .. "\027\\")
end

local function placeholders(data, cols, rows)
	rows = math.min(rows, #diacritics)
	last_id = bit.band(last_id + 1, 0xffffff)
	local id = last_id

	local b64 = vim.base64.encode(data)
	for pos = 1, #b64, 4096 do
		local control = { m = pos + 4096 > #b64 and 0 or 1 }
		if pos == 1 then
			-- transmit and make a virtual placement of cols x rows cells
			control = vim.tbl_extend("force", control, {
				a = "T",
				U = 1,
				f = 100,
				t = "d",
				i = id,
				c = cols,
				r = rows,
				q = 2,
			})
		end
		passthrough(control, b64:sub(pos, pos + 4095))
	end

	local lines = {}
	for r = 1, rows do
		-- the first cell names its row and column, the rest carry on from it
		lines[r] = placeholder
			.. vim.fn.nr2char(diacritics[r])
			.. vim.fn.nr2char(diacritics[1])
			.. placeholder:rep(cols - 1)
	end
	local hl = "KhoverImage" .. id
	vim.api.nvim_set_hl(0, hl, { fg = id })
	local buf, win = float(lines, "")
	vim.wo[win].winblend = 0
	for r = 1, rows do
		vim.api.nvim_buf_set_extmark(buf, ns, r - 1, 0, { end_col = #lines[r], hl_group = hl })
	end
	vim.api.nvim_create_autocmd("WinClosed", {
		pattern = tostring(win),
		once = true,
		callback = function()
			passthrough({ a = "d", d = "I", i = id, q = 2 })
		end,
	})
end

-- an empty float the size of the image, with the image drawn over it
local function image(path)
	local data = vim.fn.readblob(path)
	if data:sub(2, 4) ~= "PNG" then
		return float({ "not a png: " .. path }, "")
	end
	-- the IHDR chunk holds the width and height right after the signature
	local w, h = be32(data, 17), be32(data, 21)
	local cols = math.ceil(w / M.config.cell.width)
	local rows = math.ceil(h / M.config.cell.height)
	if cols > M.config.max_width then
		rows = math.ceil(rows * M.config.max_width / cols)
		cols = M.config.max_width
	end
	if vim.env.TMUX then
		return placeholders(data, cols, rows)
	end
	local lines = {}
	for i = 1, rows do
		lines[i] = string.rep(" ", cols)
	end
	local _, win = float(lines, "")
	vim.cmd.redraw()
	-- the screen position of a float is that of its border
	local pos = vim.fn.win_screenpos(win)
	local border = vim.api.nvim_win_get_config(win).border
	local pad = (border and border ~= "none" and #border > 0) and 1 or 0
	local id = vim.ui.img.set(data, {
		row = pos[1] + pad,
		col = pos[2] + pad,
		width = cols,
		height = rows,
		zindex = 50,
	})
	vim.api.nvim_create_autocmd("WinClosed", {
		pattern = tostring(win),
		once = true,
		callback = function()
			vim.ui.img.del(id)
		end,
	})
end

local function hex(n)
	return string.format("#%06x", n)
end

local function typst(src)
	local fg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).fg or 0xffffff
	local doc = table.concat({
		"#set page(width: auto, height: auto, margin: 4pt, fill: none)",
		'#set text(size: 12pt, fill: rgb("' .. hex(fg) .. '"))',
		"$ " .. src .. " $",
	}, "\n")
	local dir = vim.fn.stdpath("cache") .. "/khover"
	vim.fn.mkdir(dir, "p")
	local png = dir .. "/" .. vim.fn.sha256(doc) .. ".png"
	if vim.uv.fs_stat(png) then
		return image(png)
	end
	local cmd = { M.config.typst, "compile", "--ppi", tostring(M.config.ppi), "-", png }
	run(cmd, doc, nil, function()
		image(png)
	end)
end

local function show(p, out)
	if p.kind == "typst" then
		typst(vim.trim(out))
	elseif p.kind == "png" then
		image(vim.trim(out))
	else
		float(vim.split(out, "\n", { trimempty = true }), "markdown")
	end
end

-- K: the first provider whose text is under the cursor, or the usual K
function M.hover()
	local buf = vim.api.nvim_get_current_buf()
	for _, p in ipairs(providers[vim.bo[buf].filetype] or {}) do
		local text = capture(buf, p)
		if text then
			if p.text then
				text = p.text(text)
			end
			run(p.cmd, text, p.cwd, function(out)
				show(p, out)
			end)
			return
		end
	end
	if #vim.lsp.get_clients({ bufnr = buf, method = "textDocument/hover" }) > 0 then
		vim.lsp.buf.hover()
	else
		vim.cmd("normal! K")
	end
end

return M
