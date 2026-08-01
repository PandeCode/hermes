vim.g.zig_fmt_parse_errors = 0
vim.g.zig_fmt_autosave = 0
vim.g.zig_organise_imports = false
vim.g.zig_fix_all = false
local function bool__3estr(bool)
  if bool then
    return "true"
  else
    return "false"
  end
end
local function table_keys(tbl)
  local keys = {}
  local n = 0
  for key, _ in pairs(tbl) do
    n = (n + 1)
    keys[n] = key
  end
  return keys
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
  local function _3_(n)
    return n:type()
  end
  return find_ancestor_by(node, ancestor, _3_)
end
local function find_child_by_type(parent, child)
  if (nil ~= parent) then
    local rnode = nil
    for node, _ in parent:iter_children() do
      local _4_
      do
        rnode = node
        _4_ = (node:type() == child)
      end
      if _4_ then break end
    end
    return rnode
  else
    return nil
  end
end
local function zig_add_param(param)
  local cur_node = vim.treesitter.get_node()
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
local zig_add_io
local function _8_()
  return zig_add_param("io: std.Io")
end
zig_add_io = _8_
local zig_add_alloc
local function _9_()
  return zig_add_param("gpa: std.mem.Allocator")
end
zig_add_alloc = _9_
vim.keymap.set("n", "<leader>zz", zig_add_io, {desc = "My zig options"})
local function zig_gen_errs()
  local cur_node = vim.treesitter.get_node()
  return nil
end
local function def_ui(tbl, opts_3f)
  local function _10_(choice)
    return tbl[choice]()
  end
  return vim.ui.select(table_keys(tbl), (opts_3f or {}), _10_)
end
local function zig_ui()
  local function _11_()
  end
  local function _12_()
    vim.g.zig_fix_all = not vim.g.zig_fix_all
    return vim.print("Zig FixAll is now: ", vim.g.zig_fix_all)
  end
  return def_ui({Errors = _11_, Toggle_FixAll = _12_, Add_Io = zig_add_io, Add_Allocator = zig_add_alloc})
end
vim.api.nvim_create_user_command("HermesZig", zig_ui, {})
vim.keymap.set("n", "<leader>zu", zig_ui, {desc = "My zig options"})
local function _13_(_)
  if vim.g.zig_organise_imports then
    return vim.lsp.buf.code_action({context = {only = {"source.organizeImports"}}, apply = true})
  else
    return nil
  end
end
vim.api.nvim_create_autocmd("BufWritePre", {pattern = {"*.zig", "*.zon"}, callback = _13_})
local function _15_(_)
  if vim.g.zig_fix_all then
    return vim.lsp.buf.code_action({context = {only = {"source.fixAll"}}, apply = true})
  else
    return nil
  end
end
vim.api.nvim_create_autocmd("BufWritePre", {pattern = {"*.zig", "*.zon"}, callback = _15_})
vim.lsp.config.zls = {settings = {zls = {enable_build_on_save = true, inlay_hints_hide_redundant_param_names = true, inlay_hints_hide_redundant_param_names_last_token = true, warn_style = true, highlight_global_var_declarations = true, build_on_save_args = {"-fincremental", "-j4"}}}}
return nil
