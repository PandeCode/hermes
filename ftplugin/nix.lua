local function field(node, name)
  return node:field(name)[1]
end
local function text_of(buf, node)
  return vim.treesitter.get_node_text(node, buf)
end
local function root_of(buf)
  local parser = vim.treesitter.get_parser(buf, "nix", {error = false})
  if parser then
    return parser:parse()[1]:root()
  else
    return nil
  end
end
local function find(node, pred_3f)
  if pred_3f(node) then
    return node
  else
    local found = nil
    for child in node:iter_children() do
      if found then break end
      found = find(child, pred_3f)
    end
    return found
  end
end
local function binding(buf, node, name)
  local function _3_(_241)
    return ((_241:type() == "binding") and (_241:parent():parent() == node) and (text_of(buf, field(_241, "attrpath")) == name))
  end
  return find(node, _3_)
end
local function slice(buf, sr, sc, er, ec)
  return table.concat(vim.api.nvim_buf_get_text(buf, sr, sc, er, ec, {}), "\n")
end
local function sibling(buf, name)
  return (vim.fs.dirname(vim.api.nvim_buf_get_name(buf)) .. "/" .. name)
end
local function exists_3f(path)
  return (1 == vim.fn.filereadable(path))
end
local function open_new(path, snippet, split_3f)
  local ei = vim.o.eventignore
  vim.o.eventignore = "BufNewFile"
  local _4_
  if split_3f then
    _4_ = "split"
  else
    _4_ = "edit"
  end
  vim.cmd((_4_ .. " " .. vim.fn.fnameescape(path)))
  vim.o.eventignore = ei
  return vim.snippet.expand(snippet)
end
local function mkshell_3f(buf, node)
  return ((node:type() == "apply_expression") and (nil ~= text_of(buf, field(node, "function")):match("mkShell%w*$")))
end
local function treefmt_at(buf, shell)
  local args = field(shell, "argument")
  local packages = binding(buf, args, "packages")
  local list
  local and_6_ = packages
  if and_6_ then
    local function _7_(_241)
      return (_241:type() == "list_expression")
    end
    and_6_ = find(field(packages, "expression"), _7_)
  end
  list = and_6_
  if list then
    local er, ec = list:end_()
    local before = slice(buf, er, 0, er, (ec - 1))
    if before:match("^%s*$") then
      return {er, (ec - 1), ("  (treefmt pkgs)\n" .. before)}
    else
      return {er, (ec - 1), "(treefmt pkgs) "}
    end
  elseif (args:type() == "attrset_expression") then
    local sr, sc = args:start()
    return {sr, (sc + 1), "\n  packages = [ (treefmt pkgs) ];"}
  else
    local sr, sc = args:start()
    vim.notify("mkShell takes no attrset here, add (treefmt pkgs) to it", vim.log.levels.WARN)
    return {sr, sc, ""}
  end
end
local function let_binding(name, default)
  local from = default:match(("^([%w_.]+)%." .. vim.pesc(name) .. "$"))
  if from then
    return ("  inherit (" .. from .. ") " .. name .. ";")
  else
    return ("  " .. name .. " = " .. default .. ";")
  end
end
local function formal_lets(buf, expr)
  local lets = {}
  local formals = field(expr, "formals")
  local function _12_()
    if formals then
      return formals:iter_children()
    else
      local function _11_()
        return nil
      end
      return _11_
    end
  end
  for formal in _12_() do
    local name = ((formal:type() == "formal") and text_of(buf, field(formal, "name")))
    local default = (name and field(formal, "default"))
    if default then
      if (name ~= "pkgs") then
        table.insert(lets, let_binding(name, text_of(buf, default)))
      else
      end
    elseif (name and (name ~= "pkgs")) then
      vim.notify((name .. " has no default, the flake has no " .. name .. " to give it"), vim.log.levels.WARN)
    else
    end
  end
  if (0 < #lets) then
    return ("let\n" .. table.concat(lets, "\n") .. "\nin\n")
  else
    return ""
  end
end
local function shell_text(buf)
  local expr = field(root_of(buf), "expression")
  local fn_3f = (expr:type() == "function_expression")
  local body
  if fn_3f then
    body = field(expr, "body")
  else
    body = expr
  end
  local shell
  local function _17_(_241)
    return mkshell_3f(buf, _241)
  end
  shell = find(body, _17_)
  if shell then
    local from
    if fn_3f then
      from = body
    else
      from = shell
    end
    local sr, sc, er, ec = from:range()
    local _let_19_ = treefmt_at(buf, shell)
    local r = _let_19_[1]
    local c = _let_19_[2]
    local text = _let_19_[3]
    if (not fn_3f and (shell ~= expr)) then
      vim.notify("only the mkShell call came over", vim.log.levels.WARN)
    else
    end
    local _21_
    if fn_3f then
      _21_ = formal_lets(buf, expr)
    else
      _21_ = ""
    end
    return (_21_ .. slice(buf, sr, sc, r, c) .. text .. slice(buf, r, c, er, ec))
  else
    return nil
  end
end
local function make_flake(buf)
  local shell = shell_text(buf)
  if not shell then
    return vim.notify("no mkShell here", vim.log.levels.WARN)
  else
    local path = sibling(buf, "flake.nix")
    local devshell = shell:gsub("\n([^\n])", "\n        %1")
    local flake
    local function _24_()
      return ("default = " .. Utils.snippet_escape(devshell) .. ";")
    end
    flake = Utils.snippet("nix", "flake"):gsub("default = pkgs%.mkShell %b{};", _24_, 1)
    Utils.flake_files(vim.fs.dirname(path))
    return open_new(path, flake)
  end
end
local function outputs_of(buf, root)
  local top = field(root, "expression")
  local outputs = ((top:type() == "attrset_expression") and binding(buf, top, "outputs"))
  local f = (outputs and field(outputs, "expression"))
  local body = (f and (f:type() == "function_expression") and field(f, "body"))
  if (body and (body:type() == "let_expression")) then
    return field(body, "body")
  elseif (body and (body:type() == "attrset_expression")) then
    return body
  else
    return nil
  end
end
local function last_output(outputs)
  local function _27_(_241)
    return ((_241:type() == "binding") and (_241:parent():parent() == outputs) and (nil == _241:next_named_sibling()))
  end
  return find(outputs, _27_)
end
local package_kinds = {{"pkg", "stdenv"}, {"pkgrust", "rust"}, {"pkggo", "go"}, {"pkgzig", "zig"}}
local function local_package(kind, dir)
  local text = Utils.snippet("nix", kind, {vim.fs.basename(dir)}):gsub("src = fetchFromGitHub %b{};", "src = ./.;")
  local keep
  local function _28_(_241)
    return not ((_241 == "  fetchFromGitHub,") or _241:match("^%s*homepage = "))
  end
  keep = _28_
  return table.concat(vim.tbl_filter(keep, vim.split(text, "\n")), "\n")
end
local function add_default_package(buf)
  local outputs = outputs_of(buf, root_of(buf))
  local devshells = binding(buf, outputs, "devShells")
  local last = last_output(outputs)
  local _, c = (devshells or last):start()
  local ind = string.rep(" ", c)
  local packages = {"packages = forAll (pkgs: {", (ind .. "  default = pkgs.callPackage ./package.nix { };"), (ind .. "});")}
  if devshells then
    local r, c0 = devshells:start()
    local function _29_()
      table.insert(packages, "")
      table.insert(packages, ind)
      return packages
    end
    vim.api.nvim_buf_set_text(buf, r, c0, r, c0, _29_())
  else
    local r, c0 = last:end_()
    packages[1] = (ind .. packages[1])
    local function _30_()
      table.insert(packages, 1, "")
      table.insert(packages, 1, "")
      return packages
    end
    vim.api.nvim_buf_set_text(buf, r, c0, r, c0, _30_())
  end
  local path = sibling(buf, "package.nix")
  if not exists_3f(path) then
    local function _32_(_241)
      return _241[2]
    end
    local function _33_(kind)
      if kind then
        return open_new(path, local_package(kind[1], vim.fs.dirname(path)), true)
      else
        return nil
      end
    end
    return vim.ui.select(package_kinds, {prompt = "package.nix for", format_item = _32_}, _33_)
  else
    return nil
  end
end
local function actions(params)
  local buf = params.bufnr
  local root = root_of(buf)
  local found = {}
  if root then
    local and_36_ = not exists_3f(sibling(buf, "flake.nix"))
    if and_36_ then
      local function _37_(_241)
        return mkshell_3f(buf, _241)
      end
      and_36_ = find(root, _37_)
    end
    if and_36_ then
      local function _38_()
        return make_flake(buf)
      end
      table.insert(found, {title = "Make_Flake", action = _38_})
    else
    end
    local outputs = outputs_of(buf, root)
    if (outputs and last_output(outputs) and not binding(buf, outputs, "packages")) then
      local function _40_()
        return add_default_package(buf)
      end
      table.insert(found, {title = "Add_Default_Package", action = _40_})
    else
    end
  else
  end
  return found
end
local null_ls = require("null-ls")
if not null_ls.is_registered("nix-actions_no_show") then
  return null_ls.register({name = "nix-actions_no_show", method = {null_ls.methods.CODE_ACTION}, filetypes = {"nix"}, generator = {fn = actions}})
else
  return nil
end
