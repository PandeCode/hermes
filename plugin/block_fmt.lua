local function wrap_selection(start, stop)
  local a = vim.fn.line("v")
  local b = vim.fn.line(".")
  local top = math.min(a, b)
  local bottom = math.max(a, b)
  local indent = vim.fn.getline(top):match("^%s*")
  vim.api.nvim_feedkeys(vim.keycode("<esc>"), "nx", false)
  if stop then
    vim.api.nvim_buf_set_lines(0, bottom, bottom, false, {(indent .. stop)})
  else
  end
  return vim.api.nvim_buf_set_lines(0, (top - 1), (top - 1), false, {(indent .. start)})
end
do
  local fts_2_auto
  if (type("lua") == "table") then
    fts_2_auto = "lua"
  else
    fts_2_auto = {"lua"}
  end
  local function _3_(tbl_2_auto)
    local function _4_()
      return wrap_selection("-- stylua: ignore start", "-- stylua: ignore end")
    end
    return vim.keymap.set("x", "<space>fo", _4_, {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _3_, pattern = fts_2_auto})
  local function _5_(tbl_2_auto)
    return vim.keymap.set("n", "<space>fo", ("<esc>{o" .. "-- stylua: ignore start" .. "<esc>}O" .. "-- stylua: ignore end" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _5_, pattern = fts_2_auto})
end
do
  local fts_2_auto
  if (type("python") == "table") then
    fts_2_auto = "python"
  else
    fts_2_auto = {"python"}
  end
  local function _7_(tbl_2_auto)
    local function _8_()
      return wrap_selection("# fmt: off", "# fmt: on")
    end
    return vim.keymap.set("x", "<space>fo", _8_, {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _7_, pattern = fts_2_auto})
  local function _9_(tbl_2_auto)
    return vim.keymap.set("n", "<space>fo", ("<esc>{o" .. "# fmt: off" .. "<esc>}O" .. "# fmt: on" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _9_, pattern = fts_2_auto})
end
do
  local fts_2_auto
  if (type({"haskell", "lhaskell"}) == "table") then
    fts_2_auto = {"haskell", "lhaskell"}
  else
    fts_2_auto = {{"haskell", "lhaskell"}}
  end
  local function _11_(tbl_2_auto)
    local function _12_()
      return wrap_selection("{- ORMOLU_DISABLE -}", "{- ORMOLU_ENABLE -}")
    end
    return vim.keymap.set("x", "<space>fo", _12_, {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _11_, pattern = fts_2_auto})
  local function _13_(tbl_2_auto)
    return vim.keymap.set("n", "<space>fo", ("<esc>{o" .. "{- ORMOLU_DISABLE -}" .. "<esc>}O" .. "{- ORMOLU_ENABLE -}" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _13_, pattern = fts_2_auto})
end
do
  local fts_2_auto
  if (type({"cpp", "c"}) == "table") then
    fts_2_auto = {"cpp", "c"}
  else
    fts_2_auto = {{"cpp", "c"}}
  end
  local function _15_(tbl_2_auto)
    local function _16_()
      return wrap_selection("// clang-format off", "// clang-format on")
    end
    return vim.keymap.set("x", "<space>fo", _16_, {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _15_, pattern = fts_2_auto})
  local function _17_(tbl_2_auto)
    return vim.keymap.set("n", "<space>fo", ("<esc>{o" .. "// clang-format off" .. "<esc>}O" .. "// clang-format on" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _17_, pattern = fts_2_auto})
end
do
  local fts_2_auto
  if (type("zig") == "table") then
    fts_2_auto = "zig"
  else
    fts_2_auto = {"zig"}
  end
  local function _19_(tbl_2_auto)
    local function _20_()
      return wrap_selection("// zig fmt: off", "// zig fmt: on")
    end
    return vim.keymap.set("x", "<space>fo", _20_, {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _19_, pattern = fts_2_auto})
  local function _21_(tbl_2_auto)
    return vim.keymap.set("n", "<space>fo", ("<esc>{o" .. "// zig fmt: off" .. "<esc>}O" .. "// zig fmt: on" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _21_, pattern = fts_2_auto})
end
do
  local fts_2_auto
  if (type("nix") == "table") then
    fts_2_auto = "nix"
  else
    fts_2_auto = {"nix"}
  end
  local function _23_(tbl_2_auto)
    local function _24_()
      return wrap_selection(("# keep-" .. "sorted start"), ("# keep-" .. "sorted end"))
    end
    return vim.keymap.set("x", "<space>fo", _24_, {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _23_, pattern = fts_2_auto})
  local function _25_(tbl_2_auto)
    return vim.keymap.set("n", "<space>fo", ("<esc>{o" .. ("# keep-" .. "sorted start") .. "<esc>}O" .. ("# keep-" .. "sorted end") .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _25_, pattern = fts_2_auto})
end
do
  local fts_2_auto
  if (type("typst") == "table") then
    fts_2_auto = "typst"
  else
    fts_2_auto = {"typst"}
  end
  local function _27_(tbl_2_auto)
    local function _28_()
      return wrap_selection("/* @typstyle off */")
    end
    return vim.keymap.set("x", "<space>fo", _28_, {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _27_, pattern = fts_2_auto})
  local function _29_(tbl_2_auto)
    return vim.keymap.set("n", "<space>fo", ("<esc>{o" .. "/* @typstyle off */" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _29_, pattern = fts_2_auto})
end
do
  local fts_2_auto
  if (type({"vue", "svelte", "javascript", "typescript", "javascriptreact", "typescriptreact"}) == "table") then
    fts_2_auto = {"vue", "svelte", "javascript", "typescript", "javascriptreact", "typescriptreact"}
  else
    fts_2_auto = {{"vue", "svelte", "javascript", "typescript", "javascriptreact", "typescriptreact"}}
  end
  local function _31_(tbl_2_auto)
    local function _32_()
      return wrap_selection("// prettier-ignore")
    end
    return vim.keymap.set("x", "<space>fo", _32_, {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _31_, pattern = fts_2_auto})
  local function _33_(tbl_2_auto)
    return vim.keymap.set("n", "<space>fo", ("<esc>{o" .. "// prettier-ignore" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _33_, pattern = fts_2_auto})
end
do
  local fts_2_auto
  if (type("rust") == "table") then
    fts_2_auto = "rust"
  else
    fts_2_auto = {"rust"}
  end
  local function _35_(tbl_2_auto)
    local function _36_()
      return wrap_selection("#[rustfmt::skip]")
    end
    return vim.keymap.set("x", "<space>fo", _36_, {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _35_, pattern = fts_2_auto})
  local function _37_(tbl_2_auto)
    return vim.keymap.set("n", "<space>fo", ("<esc>{o" .. "#[rustfmt::skip]" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _37_, pattern = fts_2_auto})
end
do
  local fts_2_auto
  if (type("fennel") == "table") then
    fts_2_auto = "fennel"
  else
    fts_2_auto = {"fennel"}
  end
  local function _39_(tbl_2_auto)
    local function _40_()
      return wrap_selection(";; fnlfmt: skip")
    end
    return vim.keymap.set("x", "<space>fo", _40_, {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _39_, pattern = fts_2_auto})
  local function _41_(tbl_2_auto)
    return vim.keymap.set("n", "<space>fo", ("<esc>{o" .. ";; fnlfmt: skip" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _41_, pattern = fts_2_auto})
end
local fts_2_auto
if (type("python") == "table") then
  fts_2_auto = "python"
else
  fts_2_auto = {"python"}
end
local function _43_(tbl_2_auto)
  local function _44_()
    return wrap_selection("_t=perf_counter()", "print(f'_t:{perf_counter()-_t:.2f}s')")
  end
  return vim.keymap.set("x", "<leader>wt", _44_, {buffer = tbl_2_auto.buf})
end
vim.api.nvim_create_autocmd("Filetype", {callback = _43_, pattern = fts_2_auto})
local function _45_(tbl_2_auto)
  return vim.keymap.set("n", "<leader>wt", ("<esc>{o" .. "_t=perf_counter()" .. "<esc>}O" .. "print(f'_t:{perf_counter()-_t:.2f}s')" .. "<esc>"), {buffer = tbl_2_auto.buf})
end
return vim.api.nvim_create_autocmd("Filetype", {callback = _45_, pattern = fts_2_auto})
