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

local function load_file(custom_config_path)
	vim.notify("Sourcing custom config from: " .. custom_config_path, vim.log.levels.INFO)
	local ok, err = pcall(dofile, custom_config_path)
	if not ok then
		vim.notify("Error sourcing custom config: " .. err, vim.log.levels.ERROR)
	end
end

local db_file = vim.fn.expand("~/.cache/nvim/db_nvimrc.json")

if vim.fn.filereadable(db_file) == 0 then
	vim.fn.writefile({ "{}" }, db_file)
end

function get_hash(path)
	local algo = "sha256sum"
	local cmd = string.format("%s %q", algo, path)
	local handle = io.popen(cmd)
	if not handle then
		return nil, "popen failed"
	end
	local out = handle:read("*l")
	handle:close()
	if not out then
		return nil, "no output"
	end
	return out:match("^(%w+)")
end

function remove_file_from_db(p)
	local tbl = vim.fn.json_decode(vim.fn.readfile(db_file))
	tbl[p] = nil
	vim.fn.writefile({ vim.fn.json_encode(tbl) }, db_file)
end

function value_database(p)
	local tbl = vim.fn.json_decode(vim.fn.readfile(db_file))
	return tbl[p]
end

function add_to_database(p, v)
	local tbl = vim.fn.json_decode(vim.fn.readfile(db_file))
	tbl[p] = {
		allowed = v,
		hash = (function()
			if v then
				return get_hash(p)
			end
			return ""
		end)(),
	}
	vim.fn.writefile({ vim.fn.json_encode(tbl) }, db_file)
end

local function source_custom_config()
	local cwd = vim.fn.getcwd()
	local dirs = get_parent_dirs(cwd)

	for _, dir in ipairs(dirs) do
		local custom_config_path = dir .. "/.nvimrc.lua"
		if file_exists(custom_config_path) then
			local db_val = value_database(custom_config_path)

			if db_val == nil then
				local choice = vim.fn.confirm("Do you want to source .nvimrc.lua?", "&Yes\n&No")
				if choice == 1 then
					add_to_database(custom_config_path, true)
					load_file(custom_config_path)
				else
					vim.notify(".nvimrc.lua denied")
					add_to_database(custom_config_path, false)
				end
			else
				if db_val.allowed == true then
					if db_val.hash == get_hash(custom_config_path) then
						load_file(custom_config_path)
					else
						vim.print("File changed, Need to re-auth")
						remove_file_from_db(custom_config_path)
						source_custom_config()
					end
				else
					vim.print("Denied .nvimrc.lua file.")
				end
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
