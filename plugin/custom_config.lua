local function get_parent_dirs(_path)
  local path = _path
  local dirs = {}
  local prev = nil
  while (path and (path ~= prev)) do
    table.insert(dirs, 1, path)
    prev = path
    path = vim.fn.fnamemodify(path, ":h")
  end
  return dirs
end
local function load_file(path)
  vim.notify(("Sourcing custom config from: " .. path), vim.log.levels.INFO)
  local ok, err = pcall(dofile, path)
  if not ok then
    return vim.notify(("Error sourcing custom config: " .. err), vim.log.levels.ERROR)
  else
    return nil
  end
end
local function load_fnl_file(path)
  vim.notify(("Sourcing custom config from: " .. path), vim.log.levels.INFO)
  if Fennel then
    local ok, err = pcall(Fennel.dofile, path)
    if not ok then
      return vim.notify(("Error sourcing custom config: " .. err), vim.log.levels.ERROR)
    else
      return nil
    end
  else
    return vim.notify("no Fennel runtime available", vim.log.levels.ERROR)
  end
end
local db_file = vim.fn.expand("~/.cache/nvim/db_nvimrc.json")
if (vim.fn.filereadable(db_file) == 0) then
  vim.fn.writefile({" {}"}, db_file)
else
end
local function get_hash(path)
  local handle = io.popen(string.format("sha256sum %q", path))
  if handle then
    local out = handle:read("*l")
    handle:close()
    if out then
      return out:match("^(%w+)")
    else
      return nil
    end
  else
    return nil
  end
end
local function read_db()
  return vim.fn.json_decode(vim.fn.readfile(db_file))
end
local function write_db(tbl)
  return vim.fn.writefile({vim.fn.json_encode(tbl)}, db_file)
end
local function remove_file_from_db(p)
  local tbl = read_db()
  tbl[p] = nil
  return write_db(tbl)
end
local function value_database(p)
  return read_db()[p]
end
local function add_to_database(p, allowed)
  local tbl = read_db()
  local _7_
  if allowed then
    _7_ = get_hash(p)
  else
    _7_ = ""
  end
  tbl[p] = {allowed = allowed, hash = _7_}
  return write_db(tbl)
end
local function source_one(path, loader)
  local db_val = value_database(path)
  if (db_val == nil) then
    local choice = vim.fn.confirm("Source this config file?", "&Yes\n&No")
    if (choice == 1) then
      add_to_database(path, true)
      return loader(path)
    else
      vim.notify(("Denied: " .. path))
      return add_to_database(path, false)
    end
  else
    if db_val.allowed then
      if (db_val.hash == get_hash(path)) then
        return loader(path)
      else
        vim.print("File changed, need to re-auth")
        remove_file_from_db(path)
        return source_one(path, loader)
      end
    else
      return vim.print(("Denied: " .. path))
    end
  end
end
local function source_custom_config()
  local dirs = get_parent_dirs(vim.fn.getcwd())
  for _, dir in ipairs(dirs) do
    local lua_path = (dir .. "/.nvimrc.lua")
    local fnl_path = (dir .. "/.nvimrc.fnl")
    if (vim.fn.filereadable(lua_path) == 1) then
      source_one(lua_path, load_file)
    else
    end
    if (vim.fn.filereadable(fnl_path) == 1) then
      source_one(fnl_path, load_fnl_file)
    else
    end
  end
  return nil
end
vim.api.nvim_create_autocmd("DirChanged", {pattern = "*", callback = source_custom_config, desc = "Source custom .nvimrc.lua/.nvimrc.fnl from parent dirs up to cwd"})
return source_custom_config()
