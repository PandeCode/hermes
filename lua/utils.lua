IDE = { name = "CharonNvim: Necrology editor for CharonOS", description = "Personal Configuration of neovim" }

function ListDir(dir)
	return vim.fn.globpath(dir, "*", false, true)
end

function DeepCopy(o, seen)
	seen = seen or {}
	if o == nil then
		return nil
	end
	if seen[o] then
		return seen[o]
	end

	local no
	if type(o) == "table" then
		no = {}
		seen[o] = no

		for k, v in next, o, nil do
			no[deepcopy(k, seen)] = deepcopy(v, seen)
		end
		setmetatable(no, deepcopy(getmetatable(o), seen))
	else -- number, string, boolean, etc
		no = o
	end
	return no
end

function Dump(o)
	if type(o) == "table" then
		local s = "{ "
		for k, v in pairs(o) do
			if type(k) ~= "number" then
				k = '"' .. k .. '"'
			end
			s = s .. "[" .. k .. "] = " .. Dump(v) .. ","
		end
		return s .. "} "
	else
		return tostring(o)
	end
end

function Merge(t1, t2)
	local ret = DeepCopy(t1)
	for k, v in pairs(t2) do
		if type(v) == "table" then
			if type(ret[k] or false) == "table" then
				Merge(ret[k] or {}, t2[k] or {})
			else
				ret[k] = v
			end
		else
			ret[k] = v
		end
	end
	return ret
end

function Concat(t1, t2)
	local ret = DeepCopy(t1)
	for i = 1, #t2 do
		ret[#ret + 1] = t2[i]
	end
	return ret
end

function RandFrom(list)
	math.randomseed(os.time())
	return list[math.random(1, #list)]
end

function RandBool()
	math.randomseed(os.time())
	return math.random(0, 1) == 1
end

function RandStr(length)
	local res = ""
	for _ = 1, length do
		res = res .. string.char(math.random(97, 122))
	end
	return res
end

function GetVisualSelection()
	local s_start = vim.fn.getpos("'<")
	local s_end = vim.fn.getpos("'>")
	local n_lines = math.abs(s_end[2] - s_start[2]) + 1
	local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)
	lines[1] = string.sub(lines[1], s_start[3], -1)
	if n_lines == 1 then
		lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3] - s_start[3] + 1)
	else
		lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3])
	end
	return table.concat(lines, "\n")
end

TS = {}

function TS.GetNodeChildren(node)
	local children = {}
	for child in node:iter_children() do
		table.insert(children, child)
	end
	return children
end

function TS.GetNodeAtCursorByName(name)
	local node = vim.treesitter.get_node()
	if not node then
		vim.notify("No node found at cursor!", vim.log.levels.WARN)
		return
	end
	while node and node:type() ~= name do
		node = node:parent()
	end
	if not node then
		vim.notify("No valid node found: " .. name, vim.log.levels.WARN)
		return
	end
	return node
end

--- Get root node for file
---@param type string treesitter parser eg cpp, c, java
---@param bufnr number? buffer number {default current buffer}
---@return TSNode | nil
TS.get_root = function(type, bufnr)
	local parser = vim.treesitter.get_parser(bufnr, type, {})
	local tree = parser:parse()[1]
	return tree:root()
end

--- Find parent node of given type.
---@param node TSNode
---@param type string
---@return TSNode | nil
TS.find_parent_node = function(node, type)
	if node == node:root() then
		return nil
	end
	if node:type() == type then
		return node
	end
	return TS.find_parent_node(node:parent(), type)
end

--- Find child node of given type.
---@param node TSNode
---@param type string
---@return TSNode | nil
TS.find_child_node = function(node, type)
	local child = node:child(0)
	while child do
		if child:type() == type then
			return child
		end
		child = child:next_sibling()
	end
	return nil
end

--- Set text of given node.
---@param node TSNode
---@param text string | table
---@param bufnr number | nil
TS.set_node_text = function(node, text, bufnr)
	local sr, sc, er, ec = node:range()
	local content = { text }
	if type(text) == "table" then
		content = text
	end
	vim.api.nvim_buf_set_text(bufnr or 0, sr, sc, er, ec, content)
end

--- Get text of given node.
---@param node TSNode
---@param bufnr number | nil
---@return string | string[]
TS.get_node_text = function(node, bufnr)
	local sr, sc, er, ec = node:range()
	local text = vim.api.nvim_buf_get_text(bufnr or 0, sr, sc, er, ec, {})
	if #text == 1 then
		return text[1]
	end
	return text
end

-- stylua: ignore start
SUPERSCRIPTS = {
	["0"] = "⁰", ["1"] = "¹", ["2"] = "²", ["3"] = "³",
	["4"] = "⁴", ["5"] = "⁵", ["6"] = "⁶", ["7"] = "⁷",
	["8"] = "⁸", ["9"] = "⁹",
	["a"] = "ᵃ", ["b"] = "ᵇ", ["c"] = "ᶜ", ["d"] = "ᵈ",
	["e"] = "ᵉ", ["f"] = "ᶠ", ["g"] = "ᶢ", ["h"] = "ʰ",
	["i"] = "ⁱ", ["j"] = "ʲ", ["k"] = "ᵏ", ["l"] = "ˡ",
	["m"] = "ᵐ", ["n"] = "ⁿ", ["o"] = "ᵒ", ["p"] = "ᵖ",
	["r"] = "ʳ", ["s"] = "ˢ", ["t"] = "ᵗ", ["u"] = "ᵘ",
	["v"] = "ᵛ", ["w"] = "ʷ", ["x"] = "ˣ", ["y"] = "ʸ",
	["z"] = "ᶻ",
	["A"] = "ᴬ", ["B"] = "ᴮ", ["D"] = "ᴰ", ["E"] = "ᴱ",
	["G"] = "ᴳ", ["H"] = "ᴴ", ["I"] = "ᴵ", ["J"] = "ᴶ",
	["K"] = "ᴷ", ["L"] = "ᴸ", ["M"] = "ᴹ", ["N"] = "ᴺ",
	["O"] = "ᴼ", ["P"] = "ᴾ", ["R"] = "ᴿ", ["T"] = "ᵀ",
	["U"] = "ᵁ", ["V"] = "ⱽ", ["W"] = "ᵂ",
	["+"] = "⁺", ["-"] = "⁻", ["="] = "⁼", ["("] = "⁽",
	[")"] = "⁾"
}

SUBSCRIPTS = {
	["0"] = "₀", ["1"] = "₁", ["2"] = "₂", ["3"] = "₃",
	["4"] = "₄", ["5"] = "₅", ["6"] = "₆", ["7"] = "₇",
	["8"] = "₈", ["9"] = "₉",
	["a"] = "ₐ", ["e"] = "ₑ", ["h"] = "ₕ", ["i"] = "ᵢ",
	["j"] = "ⱼ", ["k"] = "ₖ", ["l"] = "ₗ", ["m"] = "ₘ",
	["n"] = "ₙ", ["o"] = "ₒ", ["p"] = "ₚ", ["r"] = "ᵣ",
	["s"] = "ₛ", ["t"] = "ₜ", ["u"] = "ᵤ", ["v"] = "ᵥ",
	["x"] = "ₓ",
	["+"] = "₊", ["-"] = "₋", ["="] = "₌", ["("] = "₍",
	[")"] = "₎"
}
-- stylua: ignore end

local function applyMapping(s, map)
	local result = ""

	for i = 1, #s do
		local char = s:sub(i, i)
		if map[char] then
			result = result .. map[char]
		end
	end

	return result
end

function ToSuperscript(s)
	return applyMapping(s, SUPERSCRIPTS)
end

function ToSubscript(s)
	return applyMapping(s, SUBSCRIPTS)
end

function IsEmpty(str)
	return str == nil or str == vim.NIL or str == ""
end
