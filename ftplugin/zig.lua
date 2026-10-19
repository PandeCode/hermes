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
local function uses(node, name)
  local found = false
  for child in node:iter_children() do
    found = (found or ((child:type() == "identifier") and (text_of(child) == name)) or uses(child, name))
  end
  return found
end
local function has_self(params)
  local first = params:named_child(0)
  return (first and (text_of(field(first, "name")) == "self") and first)
end
local function call_of(ref)
  local parent = (ref and ref:parent())
  local callee
  if (parent and (parent:type() == "field_expression")) then
    callee = parent
  else
    callee = ref
  end
  local call = (callee and callee:parent())
  if (call and (call:type() == "call_expression") and (call:field("function")[1] == callee)) then
    return call, (callee ~= ref)
  else
    return nil
  end
end
local function update_callers(fn_node, name)
  local name_node = field(fn_node, "name")
  local params = child_of_type(fn_node, "parameters")
  local self_3f = has_self(params)
  local count = params:named_child_count()
  local row, col = name_node:start()
  local edits = {}
  for _, client in ipairs(vim.lsp.get_clients({bufnr = 0, name = "zls"})) do
    local enc = client.offset_encoding
    local line = vim.api.nvim_buf_get_lines(0, row, (row + 1), false)[1]
    local req = {textDocument = vim.lsp.util.make_text_document_params(0), position = {line = row, character = vim.str_utfindex(line, enc, col, false)}, context = {includeDeclaration = false}}
    local uri = vim.uri_from_bufnr(0)
    local ask
    local function _12_()
      local res = client:request_sync("textDocument/references", req, 2000, 0)
      return ((res and res.result) or {})
    end
    ask = _12_
    local first = ask()
    local refs
    local and_13_ = vim.startswith(text_of(fn_node), "pub ")
    if and_13_ then
      local function _14_(_241)
        return (_241.uri == uri)
      end
      and_13_ = vim.iter(first):all(_14_)
    end
    if and_13_ then
      vim.wait(300)
      refs = ask()
    else
      refs = first
    end
    for _0, loc in ipairs(refs) do
      local buf = vim.uri_to_bufnr(loc.uri)
      local _1 = vim.fn.bufload(buf)
      local parser = vim.treesitter.get_parser(buf, "zig", {error = false})
      local r = loc.range.start.line
      local text = vim.api.nvim_buf_get_lines(buf, r, (r + 1), false)[1]
      local c = vim.str_byteindex(text, enc, loc.range.start.character, false)
      if parser then
        parser:parse()
        local ref = parser:named_node_for_range({r, c, r, c})
        local call, member_3f = call_of(ref)
        if call then
          local args = field(call, "arguments")
          local n = args:named_child_count()
          local after_self = (self_3f and member_3f and (n == count) and (n > 0))
          local er, ec
          if after_self then
            er, ec = args:named_child(0):end_()
          else
            local ar, ac = args:start()
            er, ec = ar, (ac + 1)
          end
          local text0
          if after_self then
            text0 = (", " .. name)
          elseif (n == 0) then
            text0 = name
          else
            text0 = (name .. ", ")
          end
          if not edits[buf] then
            edits[buf] = {}
          else
          end
          table.insert(edits[buf], {er, ec, text0})
        else
        end
      else
      end
    end
  end
  local calls = 0
  for buf, list in pairs(edits) do
    local function _21_(a, b)
      return ((a[1] > b[1]) or ((a[1] == b[1]) and (a[2] > b[2])))
    end
    table.sort(list, _21_)
    for _, _22_ in ipairs(list) do
      local er = _22_[1]
      local ec = _22_[2]
      local text = _22_[3]
      calls = (calls + 1)
      vim.api.nvim_buf_set_text(buf, er, ec, er, ec, {text})
    end
  end
  if (calls > 0) then
    local _23_
    if (calls == 1) then
      _23_ = ""
    else
      _23_ = "s"
    end
    vim.notify(("added " .. name .. " to " .. calls .. " call" .. _23_))
  else
  end
  return {row, col}
end
local function zig_add_param(name, type)
  local found = current_fn()
  local params = (found and child_of_type(found, "parameters"))
  if not params then
    return nil
  elseif has_param(params, name) then
    return vim.notify((name .. " is already a parameter"))
  else
    local _let_26_ = update_callers(found, name)
    local row = _let_26_[1]
    local col = _let_26_[2]
    local parser = vim.treesitter.get_parser(0, "zig")
    local _ = parser:parse()
    local fn_node = find_ancestor_by_type(parser:named_node_for_range({row, col, row, col}), "function_declaration")
    local params0 = child_of_type(fn_node, "parameters")
    local body = field(fn_node, "body")
    local _0, _1, end_row = body:range()
    local brow, bcol = body:start()
    local prow, pcol = params0:start()
    local indent = line_indent(fn_node:start())
    local one_line = (brow == end_row)
    local param = (name .. ": " .. type)
    if not uses(body, name) then
      local _27_
      if one_line then
        _27_ = ("\n" .. indent)
      else
        _27_ = ""
      end
      insert_text(brow, (bcol + 1), ("\n" .. indent .. "    _ = " .. name .. ";" .. _27_))
    else
    end
    local first = has_self(params0)
    if first then
      local srow, scol = first:end_()
      return insert_text(srow, scol, (", " .. param))
    else
      local function _30_()
        if (0 == params0:named_child_count()) then
          return param
        else
          return (param .. ", ")
        end
      end
      return insert_text(prow, (pcol + 1), _30_())
    end
  end
end
local function returned_errors(body)
  local names = {}
  local function walk(node, in_return)
    for child in node:iter_children() do
      local case_33_ = child:type()
      if (case_33_ == "function_declaration") then
      else
        local and_34_ = (case_33_ == "error_type")
        if and_34_ then
          and_34_ = in_return
        end
        if and_34_ then
          table.insert(names, text_of(child:named_child(0)))
        elseif (nil ~= case_33_) then
          local t = case_33_
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
    local or_42_ = found
    if not or_42_ then
      if ((child:type() == "variable_declaration") and (text_of(child:named_child(0)) == name) and (child:named_child(1):type() == "error_set_declaration")) then
        or_42_ = child:named_child(1)
      else
        or_42_ = nil
      end
    end
    found = or_42_
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
    local _44_
    if decl_set then
      _44_ = set_members(decl_set)
    elseif inline_set then
      _44_ = set_members(inline_set)
    else
      _44_ = {}
    end
    members = merge(_44_, found)
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
        local _48_
        if (ret:type() == "error_union_type") then
          _48_ = text_of(field(ret, "ok"))
        else
          _48_ = text_of(ret)
        end
        replace_node(ret, (name .. "!" .. _48_))
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
  local _54_
  if vim.g[flag] then
    _54_ = "on"
  else
    _54_ = "off"
  end
  return vim.notify((label .. " on save: " .. _54_))
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
  local _57_
  if vim.g.zig_fix_all then
    _57_ = ": On"
  else
    _57_ = ": Off"
  end
  local function _59_()
    return zig_toggle("zig_fix_all", "fix all")
  end
  local _60_
  if vim.g.zig_organise_imports then
    _60_ = ": On"
  else
    _60_ = ": Off"
  end
  local function _62_()
    return zig_toggle("zig_organise_imports", "organise imports")
  end
  toggles = {{title = ("Toggle_FixAll" .. _57_), action = _59_}, {title = ("Toggle_OrganiseImports" .. _60_), action = _62_}}
  if in_fn_3f(params) then
    local function _63_()
      return zig_add_param("io", "std.Io")
    end
    local function _64_()
      return zig_add_param("gpa", "std.mem.Allocator")
    end
    local function _65_()
      return zig_add_param("ctx", "Context")
    end
    return {{title = "Errors", action = zig_gen_errs}, {title = "Add_Io", action = _63_}, {title = "Add_Allocator", action = _64_}, {title = "Add_Ctx", action = _65_}, unpack(toggles)}
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
local function _69_(args)
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
vim.api.nvim_create_autocmd("BufWritePre", {group = group, buffer = 0, callback = _69_})
vim.bo.errorformat = table.concat({"%f:%l:%c: %trror: %m", "%f:%l:%c: %tote: %m", "%+Gerror: '%.%#' failed:", "%+Gthread %.%# panic: %.%#", "%-G%\\s%#%.%#/lib/zig/%.%#", "%\\s%#%f:%l:%c: 0x%*[0-9a-f] in %m", "%-G%.%#"}, ",")
vim.b.test_cmd = "zig build test"
vim.b.test_filter = "-Dtest-filter="
local function build_file()
  return vim.fs.find("build.zig", {upward = true, path = vim.fn.getcwd()})[1]
end
local function script_3f(buf)
  local first = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
  return (first and vim.startswith(first, "//usr/bin/env ") and true)
end
local function set_build_cmds(buf)
  local file = vim.fn.shellescape(vim.api.nvim_buf_get_name(buf), 1)
  if script_3f(buf) then
    vim.bo[buf]["makeprg"] = ("sh " .. file)
    vim.b[buf]["build_cmd"] = nil
    vim.b[buf]["run_cmd"] = ("sh " .. file)
    return nil
  elseif build_file() then
    vim.bo[buf]["makeprg"] = "zig build $*"
    vim.b[buf]["build_cmd"] = "zig build"
    vim.b[buf]["run_cmd"] = "zig build run -freference-trace=10 -j$(nproc)"
    return nil
  else
    vim.bo[buf]["makeprg"] = ("zig build-exe -fno-emit-bin " .. file)
    vim.b[buf]["build_cmd"] = ("zig build-exe -fno-emit-bin " .. file)
    vim.b[buf]["run_cmd"] = ("zig run -freference-trace=10 " .. file)
    return nil
  end
end
set_build_cmds(vim.api.nvim_get_current_buf())
local function _73_()
  if (vim.bo.filetype == "zig") then
    return set_build_cmds(vim.api.nvim_get_current_buf())
  else
    return nil
  end
end
vim.api.nvim_create_autocmd({"BufEnter", "BufWritePost", "DirChanged"}, {group = vim.api.nvim_create_augroup("zig_build_cmds", {clear = true}), callback = _73_})
local function test_name()
  local node = current_node()
  local test
  if (node and (node:type() == "test_declaration")) then
    test = node
  else
    test = find_ancestor_by_type(node, "test_declaration")
  end
  local name = (test and test:named_child(0))
  local case_76_ = (name and name:type())
  if (case_76_ == "identifier") then
    return text_of(name)
  elseif (case_76_ == "string") then
    local content = child_of_type(name, "string_content")
    return (content and text_of(content))
  else
    return nil
  end
end
local function zig_test_at()
  local name = test_name()
  local file = vim.api.nvim_buf_get_name(0)
  local build = build_file()
  local in_build = (build and vim.startswith(file, (vim.fs.dirname(build) .. "/")))
  local filters = (in_build and table.concat(vim.fn.readfile(build), "\n"):find("\"test-filter\"", 1, true))
  if (in_build and (filters or not name)) then
    return {name = name}
  else
    local _78_
    if name then
      _78_ = (" --test-filter " .. vim.fn.shellescape(name, 1))
    else
      _78_ = ""
    end
    return {term = ("zig test " .. vim.fn.shellescape(file, 1) .. _78_)}
  end
end
if (_G.Utils and _G.Utils.test_at) then
  _G.Utils.test_at["zig"] = zig_test_at
else
end
local function zig_pick_step()
  local function _82_(out)
    if (0 ~= out.code) then
      return vim.notify(out.stderr, vim.log.levels.ERROR)
    else
      local steps
      do
        local tbl_26_ = {}
        local i_27_ = 0
        for _, line in ipairs(vim.split(out.stdout, "\n")) do
          local val_28_ = line:match("^%s+(%S+)")
          if (nil ~= val_28_) then
            i_27_ = (i_27_ + 1)
            tbl_26_[i_27_] = val_28_
          else
          end
        end
        steps = tbl_26_
      end
      local function _84_(step)
        if step then
          vim.g.run_cmd = ("zig build " .. step)
          return _G.Utils.run()
        else
          return nil
        end
      end
      return vim.ui.select(steps, {prompt = "zig build step"}, _84_)
    end
  end
  return vim.system({"zig", "build", "-l"}, {text = true}, vim.schedule_wrap(_82_))
end
return vim.keymap.set("n", "<leader>ms", zig_pick_step, {buffer = 0, desc = "zig build step into run_cmd"})
