local function gen_enum_funcs(enum_name, bufnr)
	enum_name = enum_name or vim.fn.expand("<cword>")
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local ft = vim.bo[bufnr].filetype
	if ft ~= "cpp" and ft ~= "c" then
		vim.notify("Can only be used in c or cpp", vim.log.levels.WARN)
		return
	end
	local cpp = ft == "cpp"

	local root = vim.treesitter.get_parser(bufnr, ft):parse()[1]:root()
	local enum_data = vim.treesitter.query.parse(ft, [[
	(enum_specifier
		name: (type_identifier) @name (#eq? @name "]] .. enum_name .. [[")
		(enumerator_list
			(enumerator
				name: (identifier) @items
			)
		)
	) @enum
	]])

	local items = {}
	local start_from = 0

	for id, node in enum_data:iter_captures(root, bufnr, 0, -1) do
		local name = enum_data.captures[id]
		if name == "items" then
			table.insert(items, vim.treesitter.get_node_text(node, bufnr))
		elseif name == "enum" then
			start_from = ({ node:range() })[3] + 2
		end
	end

	if #items == 0 then
		vim.notify("Failed to get enum '" .. enum_name .. "'", vim.log.levels.ERROR)
		return
	end

	-- c enums are unscoped and are spelled `enum Name`
	local type_name = cpp and enum_name or "enum " .. enum_name
	local function value(item)
		return cpp and enum_name .. "::" .. item or item
	end

	local valid = enum_name .. "::{" .. table.concat(items, ", ") .. "}"
	local err = cpp and 'throw std::invalid_argument("Must be valid type ' .. valid .. '");'
		or 'fprintf(stderr, "Must be valid type ' .. valid .. '\\n"); abort();'

	local lines = {
		"// clang-format off",
		cpp and type_name .. " " .. enum_name .. "_fromstring(const std::string& str) {"
			or type_name .. " " .. enum_name .. "_fromstring(const char* str) {",
	}

	for _, item in ipairs(items) do
		table.insert(
			lines,
			cpp and '	if(str == "' .. item .. '") return ' .. value(item) .. ";"
				or '	if(strcmp(str, "' .. item .. '") == 0) return ' .. value(item) .. ";"
		)
	end

	table.insert(lines, "\t" .. err)
	table.insert(lines, "}")
	table.insert(
		lines,
		cpp and "std::string " .. enum_name .. "_tostring(const " .. type_name .. "& e) {"
			or "const char* " .. enum_name .. "_tostring(" .. type_name .. " e) {"
	)
	table.insert(lines, "	switch(e) {")

	for _, item in ipairs(items) do
		table.insert(lines, "		case " .. value(item) .. ': return "' .. item .. '";')
	end

	table.insert(lines, "		default: " .. err)
	table.insert(lines, "	}")
	table.insert(lines, "}")

	if cpp then
		table.insert(lines, "std::ostream& operator<<(std::ostream& stream, const " .. enum_name .. "& e) {")
		table.insert(lines, "	stream << " .. enum_name .. "_tostring(e);")
		table.insert(lines, "	return stream;")
		table.insert(lines, "}")
	end
	table.insert(lines, "// clang-format on")
	table.insert(lines, "")

	vim.api.nvim_buf_set_lines(bufnr, start_from, start_from, false, lines)
	vim.notify("Added enum functions to '" .. enum_name .. "'", vim.log.levels.INFO)
end

vim.api.nvim_create_autocmd("BufEnter", {
	pattern = { "*.cpp", "*.c" },
	group = vim.api.nvim_create_augroup("gen_enum", { clear = true }),
	callback = function(tbl)
		vim.api.nvim_buf_create_user_command(tbl.buf, "GenEnum", function()
			gen_enum_funcs()
		end, {})
		vim.keymap.set("n", "<LEADER>ge", gen_enum_funcs, { buffer = tbl.buf })
	end,
})
