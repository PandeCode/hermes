local function file_exists(file)
	local f = io.open(file, "r")
	if f then
		f:close()
		return true
	end
	return false
end

local function get_parent_dirs(path)
	local dirs = {}
	local prev = nil
	while path and path ~= prev do
		table.insert(dirs, 1, path)
		prev = path
		path = vim.fn.fnamemodify(path, ":h")
	end
	return dirs
end

local function source_custom_config()
	local cwd = vim.fn.getcwd()
	local dirs = get_parent_dirs(cwd)

	for _, dir in ipairs(dirs) do
		local custom_config_path = dir .. "/.nvimrc.lua"
		if file_exists(custom_config_path) then
			vim.notify("Sourcing custom config from: " .. custom_config_path, vim.log.levels.INFO)
			local ok, err = pcall(dofile, custom_config_path)
			if not ok then
				vim.notify("Error sourcing custom config: " .. err, vim.log.levels.ERROR)
			end
		end
	end
end

vim.api.nvim_create_autocmd("DirChanged", {
	pattern = "*",
	callback = source_custom_config,
	desc = "Source custom .nvimrc.lua from parent dirs up to cwd",
})

source_custom_config()
