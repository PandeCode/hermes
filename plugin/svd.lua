local khover = require("khover")
local function tag(xml, name)
  return xml:match(("<" .. name .. ">%s*(.-)%s*</" .. name .. ">"))
end
local function number(s)
  if s then
    local _1_
    if s:match("^0[xX]") then
      _1_ = s:sub(3)
    else
      _1_ = s
    end
    local function _3_()
      if s:match("^0[xX]") then
        return 16
      else
        return 10
      end
    end
    return tonumber(_1_, _3_())
  else
    return nil
  end
end
local function clean(s)
  if s then
    return s:gsub("%s+", " "):gsub("^ ", "")
  else
    return nil
  end
end
local function parse_register(xml)
  local _6_
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for field in xml:gmatch("<field>(.-)</field>") do
      local val_28_ = {name = tag(field, "name"), description = clean(tag(field, "description")), offset = number(tag(field, "bitOffset")), width = number(tag(field, "bitWidth"))}
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    _6_ = tbl_26_
  end
  return {name = tag(xml, "name"), description = clean(tag(xml, "description")), offset = number(tag(xml, "addressOffset")), access = tag(xml, "access"), reset = tag(xml, "resetValue"), fields = _6_}
end
local function parse(text)
  local text0 = text:gsub("<enumeratedValues>.-</enumeratedValues>", "")
  local peripherals = {}
  local by_name = {}
  for attrs, body in text0:gmatch("<peripheral([^>]*)>(.-)</peripheral>") do
    local head = (body:match("^(.-)<registers>") or body)
    local p
    local _8_
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for reg in body:gmatch("<register>(.-)</register>") do
        local val_28_ = parse_register(reg)
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      _8_ = tbl_26_
    end
    p = {name = tag(head, "name"), description = clean(tag(head, "description")), base = number(tag(head, "baseAddress")), derived = attrs:match("derivedFrom=\"([^\"]+)\""), registers = _8_}
    table.insert(peripherals, p)
    by_name[p.name] = p
  end
  for _, p in ipairs(peripherals) do
    if (p.derived and (0 == #p.registers) and by_name[p.derived]) then
      p.registers = by_name[p.derived].registers
      p.description = (p.description or by_name[p.derived].description)
    else
    end
  end
  return {peripherals = peripherals, ["by-name"] = by_name}
end
local cache = {}
local function load(path)
  local mtime = vim.uv.fs_stat(path).mtime.sec
  local hit = cache[path]
  if (hit and (hit.mtime == mtime)) then
    return hit.svd
  else
    local svd = parse(table.concat(vim.fn.readfile(path), "\n"))
    cache[path] = {mtime = mtime, svd = svd}
    return svd
  end
end
local function svd_path(buf)
  local or_12_ = vim.g.svd
  if not or_12_ then
    local root = vim.fs.root(buf, ".pyocd")
    if root then
      or_12_ = vim.fn.glob((root .. "/.pyocd/*.svd"), false, true)[1]
    else
      or_12_ = nil
    end
  end
  return or_12_
end
local function register(p, name)
  local found = nil
  for _, r in ipairs(p.registers) do
    if found then break end
    if ((r.name == name) or (r.name == (p.name .. "_" .. name)) or (r.name:gsub("^[%w]+_", "") == name)) then
      found = r
    else
    end
  end
  return found
end
local function lookup(svd, text)
  local pname, rname = text:match("^([%w_]+)%s*[%-%.]>?%s*([%w_]+)$")
  local address
  if text:match("^0[xX]%x+$") then
    address = number(text)
  else
    address = nil
  end
  local found = nil
  if pname then
    local p = svd["by-name"][pname]
    local r = (p and register(p, rname))
    if r then
      found = {p = p, r = r}
    else
    end
  elseif address then
    for _, p in ipairs(svd.peripherals) do
      if found then break end
      if (p.base == address) then
        found = {p = p}
      else
        for _0, r in ipairs(p.registers) do
          if found then break end
          if ((p.base + r.offset) == address) then
            found = {p = p, r = r}
          else
          end
        end
      end
    end
  elseif svd["by-name"][text] then
    found = {p = svd["by-name"][text]}
  else
    for _, p in ipairs(svd.peripherals) do
      if found then break end
      for _0, r in ipairs(p.registers) do
        if found then break end
        if (r.name == text) then
          found = {p = p, r = r}
        else
        end
      end
    end
  end
  return found
end
local function find_text(buf, row, col)
  return khover.match_at(buf, row, col, {"[%w_]+%s*%->%s*[%w_]+", "[%w_]+%.[%w_]+", "0[xX]%x+", "[%w_]+"})
end
local function str(s)
  return ("#\"" .. (s or ""):gsub("\\", "\\\\"):gsub("\"", "\\\"") .. "\"")
end
local function hex(n)
  return string.format("0x%08X", n)
end
local function register_doc(p, r)
  local fields
  do
    local tmp_9_ = vim.deepcopy(r.fields)
    local function _22_(_241, _242)
      return (_241.offset > _242.offset)
    end
    table.sort(tmp_9_, _22_)
    fields = tmp_9_
  end
  local cells = {}
  local bit = 31
  for _, f in ipairs(fields) do
    local top = (f.offset + f.width + -1)
    if (bit > top) then
      table.insert(cells, string.format("table.cell(colspan: %d, fill: gray.transparentize(80%%))[]", (bit - top)))
    else
    end
    local _24_
    if (#f.name > (f.width * 2)) then
      _24_ = "table.cell(colspan: %d)[#rotate(-90deg, reflow: true)[%s]]"
    else
      _24_ = "table.cell(colspan: %d)[%s]"
    end
    table.insert(cells, string.format(_24_, f.width, str(f.name)))
    bit = (f.offset - 1)
  end
  if (bit >= 0) then
    table.insert(cells, string.format("table.cell(colspan: %d, fill: gray.transparentize(80%%))[]", (bit + 1)))
  else
  end
  local _27_
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, f in ipairs(fields) do
      local val_28_
      local _28_
      if (f.width == 1) then
        _28_ = tostring(f.offset)
      else
        _28_ = ((f.offset + f.width + -1) .. ":" .. f.offset)
      end
      val_28_ = string.format("  [%s], [*%s*], [%s],", _28_, str(f.name), str(f.description))
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    _27_ = tbl_26_
  end
  return table.concat({("*" .. str(r.name) .. "* #h(1em) `" .. hex((p.base + r.offset)) .. "` #h(1em) " .. str((r.access or "")) .. " #h(1em) reset `" .. (r.reset or "?") .. "`"), "", str(r.description), "", "#set text(size: 8pt)", "#table(columns: (1.6em,) * 32, align: center + horizon, inset: 2pt, stroke: none,", "  ..range(31, -1, step: -1).map(i => [#i]))", "#v(-1em)", ("#context table(columns: (1.6em,) * 32, align: center + horizon, inset: 2pt, stroke: text.fill,\n  " .. table.concat(cells, ",\n  ") .. ")"), "#table(columns: 3, stroke: none, inset: 2pt,", table.concat(_27_, "\n"), ")"}, "\n")
end
local function peripheral_doc(p)
  local _31_
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, r in ipairs(p.registers) do
      local val_28_ = string.format("  [`+0x%03X`], [*%s*], [%s],", r.offset, str(r.name), str(r.description))
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    _31_ = tbl_26_
  end
  return table.concat({("*" .. str(p.name) .. "* #h(1em) `" .. hex(p.base) .. "`"), "", str(p.description), "", "#set text(size: 8pt)", "#table(columns: 3, stroke: none, inset: 2pt,", table.concat(_31_, "\n"), ")"}, "\n")
end
local function find(buf, row, col)
  local path = svd_path(buf)
  local text
  if path then
    text = find_text(buf, row, col)
  else
    text = nil
  end
  local hit
  if text then
    hit = lookup(load(path), text)
  else
    hit = nil
  end
  if hit then
    if hit.r then
      return register_doc(hit.p, hit.r)
    else
      return peripheral_doc(hit.p)
    end
  else
    return nil
  end
end
return khover.register({filetype = {"c", "cpp", "zig", "rust", "asm"}, key = "gK", find = find, kind = "typst_doc"})
