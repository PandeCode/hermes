do
  local fts_2_auto
  if (type("lua") == "table") then
    fts_2_auto = "lua"
  else
    fts_2_auto = {"lua"}
  end
  local function _2_(tbl_2_auto)
    return vim.keymap.set("v", "<space>fo", ("vnoremap <buffer> <SPACE>fo <esc>`>a" .. "-- stylua: ignore end" .. "<esc>`<i" .. "-- stylua: ignore start" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _2_, pattern = fts_2_auto})
  local function _3_(tbl_2_auto)
    return vim.keymap.set("n", "<space>fo", ("<esc>{o" .. "-- stylua: ignore start" .. "<esc>}O" .. "-- stylua: ignore end" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _3_, pattern = fts_2_auto})
end
do
  local fts_2_auto
  if (type("python") == "table") then
    fts_2_auto = "python"
  else
    fts_2_auto = {"python"}
  end
  local function _5_(tbl_2_auto)
    return vim.keymap.set("v", "<space>fo", ("vnoremap <buffer> <SPACE>fo <esc>`>a" .. "# fmt: on" .. "<esc>`<i" .. "# fmt: off" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _5_, pattern = fts_2_auto})
  local function _6_(tbl_2_auto)
    return vim.keymap.set("n", "<space>fo", ("<esc>{o" .. "# fmt: off" .. "<esc>}O" .. "# fmt: on" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _6_, pattern = fts_2_auto})
end
do
  local fts_2_auto
  if (type({"haskell", "lhaskell"}) == "table") then
    fts_2_auto = {"haskell", "lhaskell"}
  else
    fts_2_auto = {{"haskell", "lhaskell"}}
  end
  local function _8_(tbl_2_auto)
    return vim.keymap.set("v", "<space>fo", ("vnoremap <buffer> <SPACE>fo <esc>`>a" .. "{- ORMOLU_ENABLE -}" .. "<esc>`<i" .. "{- ORMOLU_DISABLE -}" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _8_, pattern = fts_2_auto})
  local function _9_(tbl_2_auto)
    return vim.keymap.set("n", "<space>fo", ("<esc>{o" .. "{- ORMOLU_DISABLE -}" .. "<esc>}O" .. "{- ORMOLU_ENABLE -}" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _9_, pattern = fts_2_auto})
end
do
  local fts_2_auto
  if (type({"cpp", "c"}) == "table") then
    fts_2_auto = {"cpp", "c"}
  else
    fts_2_auto = {{"cpp", "c"}}
  end
  local function _11_(tbl_2_auto)
    return vim.keymap.set("v", "<space>fo", ("vnoremap <buffer> <SPACE>fo <esc>`>a" .. "// clang-format on" .. "<esc>`<i" .. "// clang-format off" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _11_, pattern = fts_2_auto})
  local function _12_(tbl_2_auto)
    return vim.keymap.set("n", "<space>fo", ("<esc>{o" .. "// clang-format off" .. "<esc>}O" .. "// clang-format on" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _12_, pattern = fts_2_auto})
end
do
  local fts_2_auto
  if (type("zig") == "table") then
    fts_2_auto = "zig"
  else
    fts_2_auto = {"zig"}
  end
  local function _14_(tbl_2_auto)
    return vim.keymap.set("v", "<space>fo", ("vnoremap <buffer> <SPACE>fo <esc>`>a" .. "// zig fmt: on" .. "<esc>`<i" .. "// zig fmt: off" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _14_, pattern = fts_2_auto})
  local function _15_(tbl_2_auto)
    return vim.keymap.set("n", "<space>fo", ("<esc>{o" .. "// zig fmt: off" .. "<esc>}O" .. "// zig fmt: on" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _15_, pattern = fts_2_auto})
end
do
  local fts_2_auto
  if (type({"js", "ts", "tsx", "jsx", "vue", "json", "svelte", "javascript", "typescript", "javascriptreact", "typescriptreact"}) == "table") then
    fts_2_auto = {"js", "ts", "tsx", "jsx", "vue", "json", "svelte", "javascript", "typescript", "javascriptreact", "typescriptreact"}
  else
    fts_2_auto = {{"js", "ts", "tsx", "jsx", "vue", "json", "svelte", "javascript", "typescript", "javascriptreact", "typescriptreact"}}
  end
  local function _17_(tbl_2_auto)
    return vim.keymap.set("v", "<space>fo", ("<esc>`<i" .. "// prettier-ignore" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _17_, pattern = fts_2_auto})
  local function _18_(tbl_2_auto)
    return vim.keymap.set("n", "<space>fo", ("<esc>{o" .. "// prettier-ignore" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _18_, pattern = fts_2_auto})
end
do
  local fts_2_auto
  if (type("rust") == "table") then
    fts_2_auto = "rust"
  else
    fts_2_auto = {"rust"}
  end
  local function _20_(tbl_2_auto)
    return vim.keymap.set("v", "<space>fo", ("<esc>`<i" .. "#[rustfmt::skip]" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _20_, pattern = fts_2_auto})
  local function _21_(tbl_2_auto)
    return vim.keymap.set("n", "<space>fo", ("<esc>{o" .. "#[rustfmt::skip]" .. "<esc>"), {buffer = tbl_2_auto.buf})
  end
  vim.api.nvim_create_autocmd("Filetype", {callback = _21_, pattern = fts_2_auto})
end
local fts_2_auto
if (type("fennel") == "table") then
  fts_2_auto = "fennel"
else
  fts_2_auto = {"fennel"}
end
local function _23_(tbl_2_auto)
  return vim.keymap.set("v", "<space>fo", ("<esc>`<i" .. ";; fnlfmt: skip" .. "<esc>"), {buffer = tbl_2_auto.buf})
end
vim.api.nvim_create_autocmd("Filetype", {callback = _23_, pattern = fts_2_auto})
local function _24_(tbl_2_auto)
  return vim.keymap.set("n", "<space>fo", ("<esc>{o" .. ";; fnlfmt: skip" .. "<esc>"), {buffer = tbl_2_auto.buf})
end
return vim.api.nvim_create_autocmd("Filetype", {callback = _24_, pattern = fts_2_auto})
