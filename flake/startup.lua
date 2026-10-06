-- run by the startup checks: nvim --headless -c "luafile startup.lua" in an
-- empty directory. opens one file per filetype and exits non-zero on any error
local samples = {
	["a.zig"] = { 'const std = @import("std");', "", "fn add(a: u32) u32 {", "    return a;", "}" },
	["a.fnl"] = { "(fn add [a] a)" },
	["a.nix"] = { "{ pkgs, ... }:", "{", "  a = /* lua */ ''", "    print(1)", "  '';", "}" },
	["a.lua"] = { "local a = 1", "return a" },
	["a.c"] = { "enum Color { Red, Green };", "int main(void) { return 0; }" },
	["a.py"] = { "def add(a):", "    return a" },
	["a.txt"] = { "plain text" },
}

local errors = {}
local function collect(where)
	if vim.v.errmsg ~= "" then
		table.insert(errors, where .. ": " .. vim.v.errmsg)
		vim.v.errmsg = ""
	end
end

collect("startup")
for _, name in ipairs(vim.fn.sort(vim.tbl_keys(samples))) do
	vim.fn.writefile(samples[name], name)
	local ok, err = pcall(vim.cmd.edit, name)
	if not ok then
		table.insert(errors, name .. ": " .. err)
	end
	-- let FileType autocmds, treesitter and the language clients run
	vim.wait(300)
	vim.cmd.redraw()
	collect(name)
end

for line in vim.fn.execute("messages"):gmatch("[^\n]+") do
	if line:match("E%d+:") or line:match("^Error") then
		table.insert(errors, "messages: " .. line)
	end
end

if #errors > 0 then
	io.stderr:write(table.concat(errors, "\n") .. "\n")
	vim.cmd("cquit 1")
end
vim.cmd("qall!")
