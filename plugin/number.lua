local ffi = require("ffi")
local khover = require("khover")
local bases = {x = 16, b = 2, o = 8}
local widths = {[16] = 16, [2] = 64, [8] = 22}
local function read(text)
  local kind, body = text:match("^0([xXbBoO])([%x_']+)[uUlLzZ]*$")
  local base
  if kind then
    base = bases[kind:lower()]
  else
    base = nil
  end
  local digits
  if base then
    digits = body:gsub("[_']", "")
  else
    digits = nil
  end
  if (digits and (digits ~= "") and (#digits <= widths[base])) then
    local n = ffi.new("uint64_t", 0)
    local ok = true
    for d in digits:gmatch(".") do
      local v = tonumber(d, 16)
      if (v < base) then
        n = ((n * base) + v)
      else
        ok = false
      end
    end
    if ok then
      return n, base, digits
    else
      return nil
    end
  else
    return nil
  end
end
local function digits_of(n, base)
  local left = n
  local out = {}
  while (left > 0) do
    table.insert(out, 1, string.format("%x", tonumber((left % base))))
    left = (left / base)
  end
  if (#out == 0) then
    return "0"
  else
    return table.concat(out)
  end
end
local function group(s, sep, pad)
  local short = (#s % 4)
  local s0
  if (pad and (short > 0)) then
    s0 = (string.rep("0", (4 - short)) .. s)
  else
    s0 = s
  end
  local first
  if (pad or (short == 0)) then
    first = 4
  else
    first = short
  end
  local rest
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for i = (first + 1), #s0, 4 do
      local val_28_ = s0:sub(i, (i + 3))
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    rest = tbl_26_
  end
  return table.concat({s0:sub(1, first), unpack(rest)}, sep)
end
local function find(buf, row, col)
  return khover.match_at(buf, row, col, {"%f[%w]0[xXbBoO][%x_']+[uUlLzZ]*%f[^%w]"}, read)
end
local function show(text)
  local n, base, digits = read(text)
  local bin = digits_of(n, 2)
  local lines
  local _10_
  if (n == 0) then
    _10_ = ""
  else
    _10_ = ("  (" .. #bin .. " bits)")
  end
  lines = {("dec  " .. tostring(n):gsub("ULL$", "")), ("hex  0x" .. group(digits_of(n, 16), "_")), ("oct  0o" .. digits_of(n, 8)), ("bin  " .. group(bin, " ", true) .. _10_)}
  local color
  if ((base == 16) and (#digits == 6)) then
    color = ("#" .. digits:lower())
  else
    color = nil
  end
  if color then
    table.insert(lines, ("         " .. color))
  else
  end
  local buf = vim.lsp.util.open_floating_preview(lines, "", {border = "rounded", focus_id = "khover", close_events = {"CursorMoved", "CursorMovedI", "InsertEnter", "BufLeave"}})
  local ns = vim.api.nvim_create_namespace("number-hover")
  for row = 0, 3 do
    vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {end_col = 3, hl_group = "Comment"})
  end
  if color then
    vim.api.nvim_set_hl(0, "NumberSwatch", {bg = color})
    return vim.api.nvim_buf_set_extmark(buf, ns, 4, 0, {end_col = 8, hl_group = "NumberSwatch"})
  else
    return nil
  end
end
return khover.register({filetype = "*", find = find, kind = show})
