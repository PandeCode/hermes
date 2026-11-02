local ccc = require("ccc")
local khover = require("khover")
local shapes = {hex = "#%x+", num = "%f[%w]0[xX]%x+", rgb = "%f[%w]rgba?%b()", hsl = "%f[%w]hsla?%b()", vec = "%f[%w]vec[34]%s*%b()"}
local function scan(s, shape, init, read)
  local from = (init or 1)
  local found = nil
  while (from and not found) do
    local start, stop = s:find(shape, from)
    if not start then
      from = nil
    else
      local color = read(s:sub(start, stop))
      if color then
        found = {start, stop, unpack(color, 1, 2)}
      else
        from = (stop + 1)
      end
    end
  end
  if found then
    return unpack(found, 1, 4)
  else
    return nil
  end
end
local function unit(s)
  local digits = vim.trim(s):gsub("[fF]$", "")
  local n = tonumber(digits)
  if (n and (n >= 0) and (n <= 1)) then
    return n
  else
    return nil
  end
end
local function read_vec(size)
  local function _5_(text)
    local args = text:match(("^vec" .. size .. "%s*%((.*)%)$"))
    local parts
    if args then
      parts = vim.split(args, ",", {plain = true})
    else
      parts = {}
    end
    local nums
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, p in ipairs(parts) do
        local val_28_ = unit(p)
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      nums = tbl_26_
    end
    if (args and (#parts == #nums)) then
      if (#nums == 1) then
        local n = nums[1]
        local function _8_()
          if (size == 4) then
            return n
          else
            return nil
          end
        end
        return {{n, n, n}, _8_()}
      elseif (#nums == size) then
        return {{nums[1], nums[2], nums[3]}, nums[4]}
      else
        return nil
      end
    else
      return nil
    end
  end
  return _5_
end
local function read_num(text)
  local hex = text:match("^0[xX](%x%x%x%x%x%x)$")
  if hex then
    local function _11_()
      local tbl_26_ = {}
      local i_27_ = 0
      for byte in hex:gmatch("%x%x") do
        local val_28_ = (tonumber(byte, 16) / 255)
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      return tbl_26_
    end
    return {_11_()}
  else
    return nil
  end
end
local function read_ccc(picker)
  local function _14_(text)
    local start, stop, rgb, alpha = picker:parse_color(text, 1)
    if (start and (start == 1) and (stop == #text)) then
      return {rgb, alpha}
    else
      return nil
    end
  end
  return _14_
end
local function picker(shape, read)
  local function _16_(_, s, init)
    return scan(s, shape, init, read)
  end
  return {parse_color = _16_}
end
local function byte(n)
  return math.floor(((n * 255) + 0.5))
end
local function decimal(n)
  local s = string.format("%.3f", n):gsub("0+$", "")
  if vim.endswith(s, ".") then
    return (s .. "0")
  else
    return s
  end
end
local function vec_output(size)
  local function _19_(_18_, a)
    local r = _18_[1]
    local g = _18_[2]
    local b = _18_[3]
    local parts
    do
      local tbl_26_ = {}
      local i_27_ = 0
      local function _20_()
        if (size == 4) then
          return (a or 1)
        else
          return nil
        end
      end
      for _, n in ipairs({r, g, b, _20_()}) do
        local val_28_ = decimal(n)
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      parts = tbl_26_
    end
    return ("vec" .. size .. "(" .. table.concat(parts, ", ") .. ")")
  end
  return {name = ("vec" .. size), str = _19_}
end
local num_output
local function _23_(_22_)
  local r = _22_[1]
  local g = _22_[2]
  local b = _22_[3]
  return string.format("0x%02x%02x%02x", byte(r), byte(g), byte(b))
end
num_output = {name = "0xRRGGBB", str = _23_}
local rgb_output
local function _25_(_24_, a)
  local r = _24_[1]
  local g = _24_[2]
  local b = _24_[3]
  if (a and (a < 1)) then
    return string.format("rgba(%d, %d, %d, %s)", byte(r), byte(g), byte(b), decimal(a))
  else
    return string.format("rgb(%d, %d, %d)", byte(r), byte(g), byte(b))
  end
end
rgb_output = {name = "rgb", str = _25_}
local vec3_output = vec_output(3)
local notations = {{shapes.hex, read_ccc(ccc.picker.hex), ccc.input.rgb, ccc.output.hex}, {shapes.rgb, read_ccc(ccc.picker.css_rgb), ccc.input.rgb, rgb_output}, {shapes.hsl, read_ccc(ccc.picker.css_hsl), ccc.input.hsl, ccc.output.css_hsl}, {"%f[%w]vec3%s*%b()", read_vec(3), ccc.input.rgb, vec3_output}, {"%f[%w]vec4%s*%b()", read_vec(4), ccc.input.rgb, vec_output(4)}, {shapes.num, read_num, ccc.input.rgb, num_output}}
local pickers
do
  local tbl_26_ = {}
  local i_27_ = 0
  for _, _27_ in ipairs(notations) do
    local shape = _27_[1]
    local read = _27_[2]
    local val_28_ = picker(shape, read)
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  pickers = tbl_26_
end
local _29_
do
  local tbl_26_ = {}
  local i_27_ = 0
  for _, _30_ in ipairs(notations) do
    local _0 = _30_[1]
    local _1 = _30_[2]
    local _2 = _30_[3]
    local output = _30_[4]
    local val_28_ = output
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  _29_ = tbl_26_
end
local _32_
do
  local tbl_21_ = {}
  for i, _33_ in ipairs(notations) do
    local _ = _33_[1]
    local _0 = _33_[2]
    local input = _33_[3]
    local output = _33_[4]
    local k_22_, v_23_ = pickers[i], {input, output}
    if ((k_22_ ~= nil) and (v_23_ ~= nil)) then
      tbl_21_[k_22_] = v_23_
    else
    end
  end
  _32_ = tbl_21_
end
ccc.setup({pickers = pickers, outputs = _29_, recognize = {input = true, output = true, pattern = _32_}})
local function read(text)
  local found = nil
  for _, _35_ in ipairs(notations) do
    local _0 = _35_[1]
    local read_one = _35_[2]
    if found then break end
    found = read_one(text)
  end
  return found
end
local function to_hex(_36_)
  local r = _36_[1]
  local g = _36_[2]
  local b = _36_[3]
  return string.format("#%02x%02x%02x", byte(r), byte(g), byte(b))
end
local function highlighter(pattern)
  local function _37_(_, text)
    local color = read(text)
    if color then
      return MiniHipatterns.compute_hex_color_group(to_hex(color[1]), "bg")
    else
      return nil
    end
  end
  return {pattern = pattern, group = _37_, extmark_opts = {priority = 200}}
end
MiniHipatterns.config.highlighters.css_rgb = highlighter(shapes.rgb)
MiniHipatterns.config.highlighters.vec = highlighter(shapes.vec)
local function find(buf, row, col)
  return khover.match_at(buf, row, col, {shapes.hex, shapes.rgb, shapes.hsl, shapes.vec}, read)
end
local swatch_win = nil
local function show(text)
  if (swatch_win and vim.api.nvim_win_is_valid(swatch_win)) then
    vim.api.nvim_win_close(swatch_win, true)
    swatch_win = nil
    return vim.cmd.CccPick()
  else
    local _let_39_ = read(text)
    local rgb = _let_39_[1]
    local a = _let_39_[2]
    local hex = to_hex(rgb)
    local pad = "        "
    local forms = {hex, rgb_output.str(rgb, a), vec3_output.str(rgb), num_output.str(rgb)}
    local lines
    do
      local tmp_9_
      do
        local tbl_26_ = {}
        local i_27_ = 0
        for _, form in ipairs(forms) do
          local val_28_ = (pad .. " " .. form)
          if (nil ~= val_28_) then
            i_27_ = (i_27_ + 1)
            tbl_26_[i_27_] = val_28_
          else
          end
        end
        tmp_9_ = tbl_26_
      end
      table.insert(tmp_9_, "K again to pick")
      lines = tmp_9_
    end
    local buf, win = vim.lsp.util.open_floating_preview(lines, "", {border = "rounded", focus_id = "khover", close_events = {"CursorMoved", "CursorMovedI", "InsertEnter", "BufLeave"}})
    local ns = vim.api.nvim_create_namespace("color-swatch")
    vim.api.nvim_set_hl(0, "ColorSwatch", {bg = hex})
    for row = 0, (#forms - 1) do
      vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {end_col = #pad, hl_group = "ColorSwatch"})
    end
    vim.api.nvim_buf_set_extmark(buf, ns, #forms, 0, {end_col = 15, hl_group = "Comment"})
    swatch_win = win
    return nil
  end
end
return khover.register({filetype = "*", find = find, kind = show})
