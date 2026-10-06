local function eval(c)
  local case_1_ = vim.bo.ft
  if (case_1_ == "lua") then
    local expr = loadstring(("return " .. c))
    local chunk, err = loadstring(c)
    return assert((expr or chunk), err)()
  elseif (case_1_ == "vim") then
    return vim.api.nvim_exec2(c, {output = true}).output
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
  local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), {type = vim.fn.mode()})
  return eval(table.concat(lines, "\n"))
end
local function _6_()
  vim.keymap.set("n", "<leader>sf", eval_file, {buffer = true})
  local function _7_()
    return vim.notify(vim.inspect(eval_line()))
  end
  vim.keymap.set("n", "<leader>ee", _7_, {buffer = true})
  local function _8_()
    return vim.notify(vim.inspect(eval_blk()))
  end
  return vim.keymap.set("v", "<leader>ee", _8_, {buffer = true})
end
return vim.api.nvim_create_autocmd("FileType", {pattern = {"lua", "fennel", "vim"}, callback = _6_})
