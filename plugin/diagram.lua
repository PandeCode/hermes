local khover = require("khover")
vim.treesitter.language.register("dot", {"graphviz"})
vim.treesitter.language.register("json5", {"wavedrom"})
local function opener(line)
  return line:match("^([^`]*)```(%w+)%s*$")
end
local function closer_3f(line)
  return (nil ~= line:match("^[^`%w]*```[^`%w]*$"))
end
local function fence_around(lines, first, row)
  local at
  local function _1_(_241)
    return lines[((_241 - first) + 1)]
  end
  at = _1_
  local open = nil
  local close = nil
  local past = false
  local r = row
  while ((open == nil) and not past and at(r)) do
    if opener(at(r)) then
      open = r
    elseif (closer_3f(at(r)) and (r ~= row)) then
      past = true
    else
    end
    r = (r - 1)
  end
  if open then
    r = (open + 1)
    while ((close == nil) and at(r) and not opener(at(r))) do
      if closer_3f(at(r)) then
        close = r
      else
      end
      r = (r + 1)
    end
  else
  end
  if (open and close and (row <= close)) then
    return open, close
  else
    return nil
  end
end
local reach = 500
local function find(langs)
  local function _6_(buf, row, _)
    local first = math.max(0, (row - reach))
    local lines = vim.api.nvim_buf_get_lines(buf, first, (row + reach), false)
    local open, close = fence_around(lines, first, row)
    if open then
      local prefix, lang = opener(lines[((open - first) + 1)])
      local bare = vim.trim(prefix)
      local body
      do
        local tbl_26_ = {}
        local i_27_ = 0
        for _0, line in ipairs(vim.list_slice(lines, ((open - first) + 2), (close - first))) do
          local val_28_
          if vim.startswith(line, prefix) then
            val_28_ = line:sub((#prefix + 1))
          elseif ((bare ~= "") and vim.startswith(line, bare)) then
            val_28_ = line:sub((#bare + 1))
          else
            val_28_ = line
          end
          if (nil ~= val_28_) then
            i_27_ = (i_27_ + 1)
            tbl_26_[i_27_] = val_28_
          else
          end
        end
        body = tbl_26_
      end
      if vim.tbl_contains(langs, lang) then
        return table.concat(body, "\n")
      else
        return nil
      end
    else
      return nil
    end
  end
  return _6_
end
local function _11_(captures, _, source, pred, metadata)
  local id = pred[2]
  local node = captures[id][1]
  local row = node:start()
  local lines = vim.split(vim.treesitter.get_node_text(node, source), "\n")
  local open = nil
  for i, line in ipairs(lines) do
    if open then break end
    if opener(line) then
      open = i
    else
    end
  end
  if open then
    local open0, close = fence_around(lines, 1, (open + 1))
    if (open0 and (close > (open0 + 1))) then
      local _0, lang = opener(lines[open0])
      metadata["injection.language"] = lang
      metadata[id] = {range = {(row + open0), 0, (row + close + -1), 0}}
      return nil
    else
      return nil
    end
  else
    return nil
  end
end
vim.treesitter.query.add_directive("fence!", _11_, {force = true})
local function color(name, attr)
  local hl = vim.api.nvim_get_hl(0, {name = name, link = false})
  if hl[attr] then
    return string.format("#%06x", hl[attr])
  else
    return nil
  end
end
local function fg()
  return (color("Normal", "fg") or "#ffffff")
end
local function dot()
  local c = fg()
  return {"dot", "-Tsvg", "-Gbgcolor=transparent", ("-Gcolor=" .. c), ("-Gfontcolor=" .. c), ("-Ncolor=" .. c), ("-Nfontcolor=" .. c), ("-Ecolor=" .. c), ("-Efontcolor=" .. c)}
end
local function wavedrom()
  if (vim.o.background == "light") then
    return {"wavedrom"}
  else
    local bg = (color("NormalFloat", "bg") or color("Normal", "bg") or "#222222")
    local text = fg()
    local hint = (color("Comment", "fg") or "#555555")
    local skin = string.format("{\n  background: %q,\n  undefined_background: %q,\n  backgrounds: [%q, \"#0C759D\", \"#328640\", \"#9D2D0C\", \"#3C4D9F\", \"#13600B\", \"#9F3C60\", \"#903C9F\"],\n  header: { color: %q, cycle_marker_color: %q },\n  footer: { color: %q, cycle_marker_color: %q },\n  signal: {\n    marker_color: %q, name_color: %q, path_color: %q, gap_color: %q,\n    gap_background_color: %q, hint_line_color: %q, undefined_color: %q,\n    group_indicator: { color: %q, label_color: %q },\n    edge: {\n      node_text_color: %q, node_background_color: %q,\n      edge_text_color: %q, edge_text_background_color: %q,\n      edge_color: %q, edge_arrow_color: %q,\n    },\n  },\n}", bg, bg, bg, text, text, text, text, text, text, text, text, bg, hint, text, text, text, text, bg, text, bg, text, text)
    local path = (vim.fn.stdpath("cache") .. "/khover/wavedrom-" .. vim.fn.sha256(skin) .. ".json5")
    if not vim.uv.fs_stat(path) then
      vim.fn.mkdir(vim.fs.dirname(path), "p")
      vim.fn.writefile(vim.split(skin, "\n"), path)
    else
    end
    return {"wavedrom", "-s", path}
  end
end
local function svgbob()
  local c = fg()
  return {"svgbob", "--background", "transparent", "--stroke-color", c, "--fill-color", c}
end
local function d2()
  local _18_
  if (vim.o.background == "light") then
    _18_ = "0"
  else
    _18_ = "200"
  end
  return {"d2", "--theme", _18_, "--pad", "8", "-", "-"}
end
khover.register({filetype = "*", find = find({"svgbob", "bob"}), cmd = svgbob, kind = "svg"})
khover.register({filetype = "*", find = find({"d2"}), cmd = d2, kind = "svg"})
khover.register({filetype = "*", find = find({"graphviz", "dot"}), cmd = dot, kind = "svg"})
khover.register({filetype = "*", find = find({"wavedrom"}), cmd = wavedrom, kind = "svg"})
return khover.register({filetype = "*", find = find({"typst"}), kind = "typst_doc"})
