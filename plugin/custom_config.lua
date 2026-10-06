local sourced = {}
local function parent_dirs(path)
  local dirs = {path}
  for dir in vim.fs.parents(path) do
    table.insert(dirs, 1, dir)
  end
  return dirs
end
local function run(path, contents)
  if vim.endswith(path, ".fnl") then
    if Fennel then
      return Fennel.eval(contents, {filename = path})
    else
      return vim.notify("no Fennel runtime available", vim.log.levels.ERROR)
    end
  else
    return assert(load(contents, ("@" .. path)))()
  end
end
local function source_one(path)
  if (not sourced[path] and (vim.fn.filereadable(path) == 1)) then
    sourced[path] = true
    local contents = vim.secure.read(path)
    if contents then
      vim.notify(("Sourcing custom config from: " .. path))
      local ok, err = pcall(run, path, contents)
      if not ok then
        return vim.notify(("Error sourcing custom config: " .. err), vim.log.levels.ERROR)
      else
        return nil
      end
    else
      return nil
    end
  else
    return nil
  end
end
local function source_custom_config()
  for _, dir in ipairs(parent_dirs(vim.fn.getcwd())) do
    source_one((dir .. "/.nvimrc.lua"))
    source_one((dir .. "/.nvimrc.fnl"))
  end
  return nil
end
vim.api.nvim_create_autocmd("DirChanged", {pattern = "*", callback = source_custom_config, desc = "Source custom .nvimrc.lua/.nvimrc.fnl from parent dirs up to cwd"})
return source_custom_config()
