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
local function child_of_type(node, t)
  local found = nil
  for child in node:iter_children() do
    local or_5_ = found
    if not or_5_ then
      if (child:type() == t) then
        or_5_ = child
      else
        or_5_ = nil
      end
    end
    found = or_5_
  end
  return found
end
local function text_of(node)
  return vim.treesitter.get_node_text(node, 0)
end
local function field(node, name)
  return node:field(name)[1]
end
local function current_node()
  local parser = vim.treesitter.get_parser(0, "zig", {error = false})
  if parser then
    parser:parse()
    return vim.treesitter.get_node()
  else
    return nil
  end
end
local function current_fn()
  local node = current_node()
  local fn_node
  if (node and (node:type() == "function_declaration")) then
    fn_node = node
  else
    fn_node = find_ancestor_by_type(node, "function_declaration")
  end
  if not fn_node then
    return vim.notify("not in a function", vim.log.levels.WARN)
  elseif not field(fn_node, "body") then
    return vim.notify("extern function, no body", vim.log.levels.WARN)
  else
    return fn_node
  end
end
local function line_indent(row)
  return vim.api.nvim_buf_get_lines(0, row, (row + 1), false)[1]:match("^%s*")
end
local function replace_node(node, text)
  local sr, sc, er, ec = node:range()
  return vim.api.nvim_buf_set_text(0, sr, sc, er, ec, vim.split(text, "\n"))
end
local function insert_text(row, col, text)
  return vim.api.nvim_buf_set_text(0, row, col, row, col, vim.split(text, "\n"))
end
local function has_param(params, name)
  local found = false
  for child in params:iter_children() do
    found = (found or ((child:type() == "parameter") and (text_of(field(child, "name")) == name)))
  end
  return found
end
local function zig_add_param(name, type)
  local fn_node = current_fn()
  local params = (fn_node and child_of_type(fn_node, "parameters"))
  if not params then
    return nil
  elseif has_param(params, name) then
    return vim.notify((name .. " is already a parameter"))
  else
    local body = field(fn_node, "body")
    local _, _0, end_row = body:range()
    local brow, bcol = body:start()
    local prow, pcol = params:start()
    local indent = line_indent(fn_node:start())
    local one_line = (brow == end_row)
    local param = (name .. ": " .. type)
    local _10_
    if one_line then
      _10_ = ("\n" .. indent)
    else
      _10_ = ""
    end
    insert_text(brow, (bcol + 1), ("\n" .. indent .. "    _ = " .. name .. ";" .. _10_))
    local first = params:named_child(0)
    local self_3f = (first and (text_of(field(first, "name")) == "self"))
    if self_3f then
      local srow, scol = first:end_()
      return insert_text(srow, scol, (", " .. param))
    else
      local function _12_()
        if (0 == params:named_child_count()) then
          return param
        else
          return (param .. ", ")
        end
      end
      return insert_text(prow, (pcol + 1), _12_())
    end
  end
end
local function returned_errors(body)
  local names = {}
  local function walk(node, in_return)
    for child in node:iter_children() do
      local case_15_ = child:type()
      if (case_15_ == "function_declaration") then
      else
        local and_16_ = (case_15_ == "error_type")
        if and_16_ then
          and_16_ = in_return
        end
        if and_16_ then
          table.insert(names, text_of(child:named_child(0)))
        elseif (nil ~= case_15_) then
          local t = case_15_
          walk(child, (in_return or (t == "return_expression")))
        else
        end
      end
    end
    return nil
  end
  walk(body, false)
  return names
end
local function set_members(set_node)
  local tbl_26_ = {}
  local i_27_ = 0
  for child in set_node:iter_children() do
    local val_28_
    if (child:type() == "identifier") then
      val_28_ = text_of(child)
    else
      val_28_ = nil
    end
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function merge(existing, found)
  local seen
  do
    local tbl_21_ = {}
    for _, n in ipairs(existing) do
      local k_22_, v_23_ = n, true
      if ((k_22_ ~= nil) and (v_23_ ~= nil)) then
        tbl_21_[k_22_] = v_23_
      else
      end
    end
    seen = tbl_21_
  end
  local out
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, n in ipairs(existing) do
      local val_28_ = n
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    out = tbl_26_
  end
  for _, n in ipairs(found) do
    if not seen[n] then
      seen[n] = true
      table.insert(out, n)
    else
    end
  end
  return out
end
local function find_set_decl(fn_node, name)
  local found = nil
  for child in fn_node:parent():iter_children() do
    local or_24_ = found
    if not or_24_ then
      if ((child:type() == "variable_declaration") and (text_of(child:named_child(0)) == name) and (child:named_child(1):type() == "error_set_declaration")) then
        or_24_ = child:named_child(1)
      else
        or_24_ = nil
      end
    end
    found = or_24_
  end
  return found
end
local function insert_set_decl(fn_node, decl)
  local row = fn_node:start()
  while ((row > 0) and vim.api.nvim_buf_get_lines(0, (row - 1), row, false)[1]:match("^%s*///")) do
    row = (row - 1)
  end
  return vim.api.nvim_buf_set_lines(0, row, row, false, {(line_indent(fn_node:start()) .. decl)})
end
local function zig_gen_errs()
  local fn_node = current_fn()
  if fn_node then
    local name = (text_of(field(fn_node, "name")) .. "_errors")
    local ret = field(fn_node, "type")
    local err = ((ret:type() == "error_union_type") and field(ret, "error"))
    local decl_set = find_set_decl(fn_node, name)
    local inline_set = (err and (err:type() == "error_set_declaration") and err)
    local found = returned_errors(field(fn_node, "body"))
    local members
    local _26_
    if decl_set then
      _26_ = set_members(decl_set)
    elseif inline_set then
      _26_ = set_members(inline_set)
    else
      _26_ = {}
    end
    members = merge(_26_, found)
    local set_text
    if (1 == #members) then
      set_text = ("error{" .. members[1] .. "}")
    else
      set_text = ("error{ " .. table.concat(members, ", ") .. " }")
    end
    local pub
    if vim.startswith(text_of(fn_node), "pub ") then
      pub = "pub "
    else
      pub = ""
    end
    if (0 == #members) then
      return vim.notify("no return error.X in this function")
    elseif (err and not inline_set and (text_of(err) ~= name)) then
      return vim.notify(("returns " .. text_of(err) .. ", left alone"))
    else
      if not err then
        local _30_
        if (ret:type() == "error_union_type") then
          _30_ = text_of(field(ret, "ok"))
        else
          _30_ = text_of(ret)
        end
        replace_node(ret, (name .. "!" .. _30_))
      elseif inline_set then
        replace_node(inline_set, name)
      else
      end
      if decl_set then
        return replace_node(decl_set, set_text)
      else
        return insert_set_decl(fn_node, (pub .. "const " .. name .. " = " .. set_text .. ";"))
      end
    end
  else
    return nil
  end
end
local function zig_toggle(flag, label)
  vim.g[flag] = not vim.g[flag]
  local _36_
  if vim.g[flag] then
    _36_ = "on"
  else
    _36_ = "off"
  end
  return vim.notify((label .. " on save: " .. _36_))
end
local null_ls = require("null-ls")
local function in_fn_3f(params)
  local parser = vim.treesitter.get_parser(params.bufnr, "zig", {error = false})
  if parser then
    parser:parse()
    local node = parser:named_node_for_range({(params.row - 1), params.col, (params.row - 1), params.col})
    return (node and ((node:type() == "function_declaration") or find_ancestor_by_type(node, "function_declaration")))
  else
    return nil
  end
end
local function zig_actions(params)
  local toggles
  local _39_
  if vim.g.zig_fix_all then
    _39_ = ": On"
  else
    _39_ = ": Off"
  end
  local function _41_()
    return zig_toggle("zig_fix_all", "fix all")
  end
  local _42_
  if vim.g.zig_organise_imports then
    _42_ = ": On"
  else
    _42_ = ": Off"
  end
  local function _44_()
    return zig_toggle("zig_organise_imports", "organise imports")
  end
  toggles = {{title = ("Toggle_FixAll" .. _39_), action = _41_}, {title = ("Toggle_OrganiseImports" .. _42_), action = _44_}}
  if in_fn_3f(params) then
    local function _45_()
      return zig_add_param("io", "std.Io")
    end
    local function _46_()
      return zig_add_param("gpa", "std.mem.Allocator")
    end
    local function _47_()
      return zig_add_param("ctx", "Context")
    end
    return {{title = "Errors", action = zig_gen_errs}, {title = "Add_Io", action = _45_}, {title = "Add_Allocator", action = _46_}, {title = "Add_Ctx", action = _47_}, unpack(toggles)}
  else
    return toggles
  end
end
if not null_ls.is_registered("zig-actions_no_show") then
  null_ls.register({name = "zig-actions_no_show", method = {null_ls.methods.CODE_ACTION}, filetypes = {"zig"}, generator = {fn = zig_actions}})
else
end
local group = vim.api.nvim_create_augroup("zig_on_save", {clear = false})
vim.api.nvim_clear_autocmds({group = group, buffer = 0})
local function apply_source_action(buf, kind)
  for _, client in ipairs(vim.lsp.get_clients({bufnr = buf, name = "zls"})) do
    local params = {textDocument = vim.lsp.util.make_text_document_params(buf), range = {start = {line = 0, character = 0}, ["end"] = {line = vim.api.nvim_buf_line_count(buf), character = 0}}, context = {only = {kind}, diagnostics = {}}}
    local res = client:request_sync("textDocument/codeAction", params, 1000, buf)
    for _0, action in ipairs(((res and res.result) or {})) do
      if action.edit then
        vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
      else
      end
    end
  end
  return nil
end
local function _51_(args)
  if vim.g.zig_organise_imports then
    apply_source_action(args.buf, "source.organizeImports")
  else
  end
  if vim.g.zig_fix_all then
    return apply_source_action(args.buf, "source.fixAll")
  else
    return nil
  end
end
vim.api.nvim_create_autocmd("BufWritePre", {group = group, buffer = 0, callback = _51_})
vim.bo.makeprg = "zig build $*"
vim.bo.errorformat = "%f:%l:%c: %trror: %m,%f:%l:%c: %tote: %m,%-G%.%#"
vim.b.build_cmd = "zig build"
vim.b.run_cmd = "zig build run -freference-trace=10 -j$(nproc)"
return nil
