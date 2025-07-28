IDE = { name = "" }
-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                                    Utils                                     ║
-- ║              A comprehensive utility library for Neovim/Lua                 ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

Utils = {}

-- ┌──────────────────────────────────────────────────────────────────────────────┐
-- │                              File System utilities                           │
-- └──────────────────────────────────────────────────────────────────────────────┘
Utils.fs = {}

--- List all files and directories in a given directory
---@param dir string The directory path to list
---@return table A list of file and directory paths
function Utils.fs.list_dir(dir)
	return vim.fn.globpath(dir, "*", false, true)
end

-- ┌──────────────────────────────────────────────────────────────────────────────┐
-- │                               Table utilities                                │
-- └──────────────────────────────────────────────────────────────────────────────┘
Utils.tbl = {}

--- Create a deep copy of a table, handling circular references
---@param o any The object to copy (table, string, number, boolean, etc.)
---@param seen table? Internal table to track circular references
---@return any A deep copy of the original object
function Utils.tbl.deep_copy(o, seen)
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
			no[Utils.tbl.deep_copy(k, seen)] = Utils.tbl.deep_copy(v, seen)
		end
		setmetatable(no, Utils.tbl.deep_copy(getmetatable(o), seen))
	else -- number, string, boolean, etc
		no = o
	end
	return no
end

--- Convert a table to a string representation for debugging
---@param o any The object to dump (works best with tables)
---@return string A string representation of the object
function Utils.tbl.dump(o)
	if type(o) == "table" then
		local s = "{ "
		for k, v in pairs(o) do
			if type(k) ~= "number" then
				k = '"' .. k .. '"'
			end
			s = s .. "[" .. k .. "] = " .. Utils.tbl.dump(v) .. ","
		end
		return s .. "} "
	else
		return tostring(o)
	end
end

--- Merge two tables together, with t2 values overriding t1 values
--- Performs deep merging for nested tables
---@param t1 table The base table
---@param t2 table The table to merge into t1
---@return table A new merged table (original tables are unchanged)
function Utils.tbl.merge(t1, t2)
	local ret = Utils.tbl.deep_copy(t1)
	for k, v in pairs(t2) do
		if type(v) == "table" then
			if type(ret[k] or false) == "table" then
				Utils.tbl.merge(ret[k] or {}, t2[k] or {})
			else
				ret[k] = v
			end
		else
			ret[k] = v
		end
	end
	return ret
end

--- Concatenate two array-like tables
---@param t1 table The first array table
---@param t2 table The second array table to append
---@return table A new table containing all elements from both arrays
function Utils.tbl.concat(t1, t2)
	local ret = Utils.tbl.deep_copy(t1)
	for i = 1, #t2 do
		ret[#ret + 1] = t2[i]
	end
	return ret
end

-- ┌──────────────────────────────────────────────────────────────────────────────┐
-- │                              Random utilities                                │
-- └──────────────────────────────────────────────────────────────────────────────┘
Utils.random = {}

--- Select a random element from a list
---@param list table An array-like table to select from
---@return any A random element from the list
function Utils.random.from(list)
	math.randomseed(os.time())
	return list[math.random(1, #list)]
end

--- Generate a random boolean value
---@return boolean A random true or false value
function Utils.random.bool()
	math.randomseed(os.time())
	return math.random(0, 1) == 1
end

--- Generate a random string of lowercase letters
---@param length number The desired length of the random string
---@return string A random string of the specified length
function Utils.random.string(length)
	local res = ""
	for _ = 1, length do
		res = res .. string.char(math.random(97, 122))
	end
	return res
end

-- ┌──────────────────────────────────────────────────────────────────────────────┐
-- │                               Vim utilities                                  │
-- └──────────────────────────────────────────────────────────────────────────────┘
Utils.vim = {}

--- Get the currently selected text in visual mode
---@return string The text that is currently visually selected
function Utils.vim.get_visual_selection()
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

-- ┌──────────────────────────────────────────────────────────────────────────────┐
-- │                            TreeSitter utilities                             │
-- └──────────────────────────────────────────────────────────────────────────────┘
Utils.treesitter = {}

--- Get all direct children of a TreeSitter node
---@param node TSNode The TreeSitter node to get children from
---@return table An array of child nodes
function Utils.treesitter.get_node_children(node)
	local children = {}
	for child in node:iter_children() do
		table.insert(children, child)
	end
	return children
end

--- Find a TreeSitter node of a specific type at or above the cursor position
---@param name string The node type to search for (e.g., "function_definition")
---@return TSNode|nil The found node or nil if not found
function Utils.treesitter.get_node_at_cursor_by_name(name)
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

--- Get the root TreeSitter node for a file
---@param type string The treesitter parser type (e.g., "cpp", "c", "java", "lua")
---@param bufnr number? The buffer number (defaults to current buffer)
---@return TSNode|nil The root node of the syntax tree, or nil if parsing fails
function Utils.treesitter.get_root(type, bufnr)
	local parser = vim.treesitter.get_parser(bufnr, type, {})
	local tree = parser:parse()[1]
	return tree:root()
end

--- Find the nearest parent node of a given type by traversing up the tree
---@param node TSNode The starting node to search from
---@param type string The node type to search for (e.g., "function_definition")
---@return TSNode|nil The parent node of the specified type, or nil if not found
function Utils.treesitter.find_parent_node(node, type)
	if node == node:root() then
		return nil
	end
	if node:type() == type then
		return node
	end
	return Utils.treesitter.find_parent_node(node:parent(), type)
end

--- Find the first child node of a given type
---@param node TSNode The parent node to search within
---@param type string The node type to search for (e.g., "identifier")
---@return TSNode|nil The first child node of the specified type, or nil if not found
function Utils.treesitter.find_child_node(node, type)
	local child = node:child(0)
	while child do
		if child:type() == type then
			return child
		end
		child = child:next_sibling()
	end
	return nil
end

--- Replace the text content of a TreeSitter node
---@param node TSNode The node whose text should be replaced
---@param text string|table The new text content (string or array of lines)
---@param bufnr number? The buffer number (defaults to current buffer)
function Utils.treesitter.set_node_text(node, text, bufnr)
	local sr, sc, er, ec = node:range()
	local content = { text }
	if type(text) == "table" then
		content = text
	end
	vim.api.nvim_buf_set_text(bufnr or 0, sr, sc, er, ec, content)
end

--- Get the text content of a TreeSitter node
---@param node TSNode The node to extract text from
---@param bufnr number? The buffer number (defaults to current buffer)
---@return string|string[] The text content (single string for single line, array for multiple lines)
function Utils.treesitter.get_node_text(node, bufnr)
	local sr, sc, er, ec = node:range()
	local text = vim.api.nvim_buf_get_text(bufnr or 0, sr, sc, er, ec, {})
	if #text == 1 then
		return text[1]
	end
	return text
end

-- ┌──────────────────────────────────────────────────────────────────────────────┐
-- │                            Text formatting utilities                         │
-- └──────────────────────────────────────────────────────────────────────────────┘
Utils.text = {}

-- stylua: ignore start
local SUPERSCRIPTS = {
	["0"] = "⁰",
	["1"] = "¹",
	["2"] = "²",
	["3"] = "³",
	["4"] = "⁴",
	["5"] = "⁵",
	["6"] = "⁶",
	["7"] = "⁷",
	["8"] = "⁸",
	["9"] = "⁹",
	["a"] = "ᵃ",
	["b"] = "ᵇ",
	["c"] = "ᶜ",
	["d"] = "ᵈ",
	["e"] = "ᵉ",
	["f"] = "ᶠ",
	["g"] = "ᶢ",
	["h"] = "ʰ",
	["i"] = "ⁱ",
	["j"] = "ʲ",
	["k"] = "ᵏ",
	["l"] = "ˡ",
	["m"] = "ᵐ",
	["n"] = "ⁿ",
	["o"] = "ᵒ",
	["p"] = "ᵖ",
	["r"] = "ʳ",
	["s"] = "ˢ",
	["t"] = "ᵗ",
	["u"] = "ᵘ",
	["v"] = "ᵛ",
	["w"] = "ʷ",
	["x"] = "ˣ",
	["y"] = "ʸ",
	["z"] = "ᶻ",
	["A"] = "ᴬ",
	["B"] = "ᴮ",
	["D"] = "ᴰ",
	["E"] = "ᴱ",
	["G"] = "ᴳ",
	["H"] = "ᴴ",
	["I"] = "ᴵ",
	["J"] = "ᴶ",
	["K"] = "ᴷ",
	["L"] = "ᴸ",
	["M"] = "ᴹ",
	["N"] = "ᴺ",
	["O"] = "ᴼ",
	["P"] = "ᴾ",
	["R"] = "ᴿ",
	["T"] = "ᵀ",
	["U"] = "ᵁ",
	["V"] = "ⱽ",
	["W"] = "ᵂ",
	["+"] = "⁺",
	["-"] = "⁻",
	["="] = "⁼",
	["("] = "⁽",
	[")"] = "⁾"
}

local SUBSCRIPTS = {
	["0"] = "₀",
	["1"] = "₁",
	["2"] = "₂",
	["3"] = "₃",
	["4"] = "₄",
	["5"] = "₅",
	["6"] = "₆",
	["7"] = "₇",
	["8"] = "₈",
	["9"] = "₉",
	["a"] = "ₐ",
	["e"] = "ₑ",
	["h"] = "ₕ",
	["i"] = "ᵢ",
	["j"] = "ⱼ",
	["k"] = "ₖ",
	["l"] = "ₗ",
	["m"] = "ₘ",
	["n"] = "ₙ",
	["o"] = "ₒ",
	["p"] = "ₚ",
	["r"] = "ᵣ",
	["s"] = "ₛ",
	["t"] = "ₜ",
	["u"] = "ᵤ",
	["v"] = "ᵥ",
	["x"] = "ₓ",
	["+"] = "₊",
	["-"] = "₋",
	["="] = "₌",
	["("] = "₍",
	[")"] = "₎"
}
-- stylua: ignore end

--- Apply character mapping to a string using the provided mapping table
---@param s string The input string to transform
---@param map table A mapping table where keys are characters and values are replacements
---@return string The transformed string with mapped characters
local function apply_mapping(s, map)
	local result = ""
	for i = 1, #s do
		local char = s:sub(i, i)
		if map[char] then
			result = result .. map[char]
		end
	end
	return result
end

--- Convert text to Unicode superscript characters
--- Supports digits (0-9), letters (a-z, A-Z), and some symbols (+, -, =, (, ))
---@param s string The input string to convert to superscript
---@return string The string with supported characters converted to superscript Unicode
function Utils.text.to_superscript(s)
	return apply_mapping(s, SUPERSCRIPTS)
end

--- Convert text to Unicode subscript characters
--- Supports digits (0-9), some letters (a, e, h, i, j, k, l, m, n, o, p, r, s, t, u, v, x), and some symbols
---@param s string The input string to convert to subscript
---@return string The string with supported characters converted to subscript Unicode
function Utils.text.to_subscript(s)
	return apply_mapping(s, SUBSCRIPTS)
end

--- Check if a string is empty, nil, or vim.NIL
---@param str string? The string to check
---@return boolean True if the string is empty, nil, or vim.NIL; false otherwise
function Utils.text.is_empty(str)
	return str == nil or str == vim.NIL or str == ""
end

-- Export the Utils table for potential module usage
-- Usage: local Utils = require('path.to.this.file')
return Utils
