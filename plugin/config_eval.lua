local function eval(c)
  local case_1_ = vim.bo.ft
  if (case_1_ == "lua") then
    return loadstring(c)
  elseif (case_1_ == "vim") then
    return vim.cmd(c)
  elseif (case_1_ == "fennel") then
    if Fennel then
      return Fennel.eval(c)
    else
      return vim.notify("no Fennel", vim.log.levels.WARN)
    end
  else
    return nil
  end
end
local function eval_file()
  local case_4_ = vim.bo.ft
  if (case_4_ == "lua") then
    return vim.cmd("luafile %")
  elseif (case_4_ == "vim") then
    return vim.cmd("source %")
  elseif (case_4_ == "fennel") then
    return eval(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"))
  else
    return nil
  end
end
local function eval_line()
  return eval(vim.api.nvim_get_current_line())
end
local function eval_blk()
  local start = vim.api.nvim_buf_get_mark(0, "<")
  local _end = vim.api.nvim_buf_get_mark(0, ">")
  local lines = vim.api.nvim_buf_get_lines(0, (start[1] - 1), _end[1], false)
  return eval(table.concat(lines, "\n"))
end
local function _6_()
  vim.keymap.set("n", "<leader>sf", eval_file, {buffer = true})
  local function _7_()
    return vim.notify(eval_line())
  end
  vim.keymap.set("n", "<leader>ee", _7_, {buffer = true})
  local function _8_()
    return vim.notify(eval_blk())
  end
  return vim.keymap.set("v", "<leader>ee", _8_, {buffer = true})
end
return vim.api.nvim_create_autocmd("FileType", {pattern = {"lua", "fennel", "vim"}, callback = _6_})
