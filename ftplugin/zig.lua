vim.g.zig_fmt_parse_errors = 0
vim.g.zig_fmt_autosave = 0
if (vim.g.zig_organise_imports == nil) then
  vim.g.zig_organise_imports = false
else
end
if (vim.g.zig_fix_all == nil) then
  vim.g.zig_fix_all = false
else
end
local function get_from(sr, sc, er, ec)
  return vim.api.nvim_buf_get_lines(0, sr, er, false)
end
local function insert_at(row, col, text)
  local buf = 0
  local lnum = (row + 1)
  local line = vim.api.nvim_buf_get_lines(buf, (lnum - 1), lnum, false)[1]
  local before = line:sub(1, col)
  local after = line:sub((col + 1))
  return vim.api.nvim_buf_set_lines(buf, (lnum - 1), lnum, false, {(before .. text .. after)})
end
local function find_ancestor_by(node, ancestor, query)
  if (nil ~= node) then
    local parent = node:parent()
    while ((nil ~= parent) and (query(parent) ~= ancestor)) do
      parent = parent:parent()
    end
    return parent
  else
    return nil
  end
end
local function find_ancestor_by_type(node, ancestor)
  local function _4_(n)
    return n:type()
  end
  return find_ancestor_by(node, ancestor, _4_)
end
local function find_child_by(parent, child, query)
  if (nil ~= parent) then
    local rnode = nil
    for node, _ in parent:iter_children() do
      local _5_
      do
        rnode = node
        _5_ = (query(node) == child)
      end
      if _5_ then break end
    end
    return rnode
  else
    return nil
  end
end
local function find_child_by_type(parent, child)
  local function _7_(n)
    return n:type()
  end
  return find_child_by(parent, child, _7_)
end
local function current_node()
  vim.treesitter.get_parser():parse()
  return vim.treesitter.get_node()
end
local function zig_add_param(param)
  local cur_node = current_node()
  local parent_fn = find_ancestor_by_type(cur_node, "function_declaration")
  local params = find_child_by_type(parent_fn, "parameters")
  if params then
    local row, col, _ = params:start()
    local text
    if (2 == params:child_count()) then
      text = param
    else
      text = (param .. ", ")
    end
    return insert_at(row, (1 + col), text)
  else
    return nil
  end
end
local function zig_gen_errs()
  local cur_node = current_node()
  local parent_fn = find_ancestor_by_type(cur_node, "function_declaration")
  if parent_fn then
    local body = parent_fn:field("body")[1]
    local start_row, start_col, end_row, end_col = body:range()
    local fn_body = get_from(start_row, start_col, (end_row + 1), end_col)
    return vim.notify(vim.inspect(fn_body))
  else
    return nil
  end
end
local function zig_toggle_fixall()
  vim.g.zig_fix_all = not vim.g.zig_fix_all
  return vim.print("Zig FixAll is now: ", vim.g.zig_fix_all)
end
local null_ls = require("null-ls")
if not null_ls.is_registered("zig-actions_no_show") then
  local function _11_()
    local _12_
    if vim.g.zig_fix_all then
      _12_ = ": On"
    else
      _12_ = ": Off"
    end
    local function _14_()
      return zig_add_param("io: std.Io")
    end
    local function _15_()
      return zig_add_param("gpa: std.mem.Allocator")
    end
    return {{title = "Errors", action = zig_gen_errs}, {title = ("Toggle_FixAll" .. _12_), action = zig_toggle_fixall}, {title = "Add_Io", action = _14_}, {title = "Add_Allocator", action = _15_}}
  end
  null_ls.register({name = "zig-actions_no_show", method = {null_ls.methods.CODE_ACTION}, filetypes = {"zig"}, generator = {fn = _11_}})
else
end
local group = vim.api.nvim_create_augroup("zig_on_save", {clear = false})
vim.api.nvim_clear_autocmds({group = group, buffer = 0})
local function _17_(_)
  if vim.g.zig_organise_imports then
    vim.lsp.buf.code_action({context = {only = {"source.organizeImports"}}, apply = true})
  else
  end
  if vim.g.zig_fix_all then
    return vim.lsp.buf.code_action({context = {only = {"source.fixAll"}}, apply = true})
  else
    return nil
  end
end
vim.api.nvim_create_autocmd("BufWritePre", {group = group, buffer = 0, callback = _17_})
vim.lsp.config.zls = {settings = {zls = {enable_build_on_save = true, inlay_hints_hide_redundant_param_names = true, inlay_hints_hide_redundant_param_names_last_token = true, warn_style = true, highlight_global_var_declarations = true, build_on_save_args = {"-fincremental", "-j4"}}}}
return nil
