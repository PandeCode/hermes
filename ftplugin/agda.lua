local function map(lhs, cmd, desc)
  return vim.keymap.set("n", lhs, ("<Cmd>" .. cmd .. "<CR>"), {buffer = true, desc = ("Agda: " .. desc)})
end
local bindings = {{"l", "CornelisLoad", "load"}, {"?", "CornelisGoals", "goals"}, {"s", "CornelisSolve", "solve constraints"}, {"xr", "CornelisRestart", "restart agda"}, {"xa", "CornelisAbort", "abort"}, {"<Space>", "CornelisGive", "give"}, {"r", "CornelisRefine", "refine"}, {"m", "CornelisElaborate", "elaborate and give"}, {"a", "CornelisAuto", "auto"}, {"c", "CornelisMakeCase", "case split"}, {",", "CornelisTypeContext", "goal type and context"}, {".", "CornelisTypeContextInfer", "goal type, context and inferred type"}, {"d", "CornelisTypeInfer", "infer type"}, {"n", "CornelisNormalize", "compute normal form"}, {"w", "CornelisWhyInScope", "why in scope"}, {"h", "CornelisHelperFunc", "helper function type"}}
for _, _1_ in ipairs(bindings) do
  local k = _1_[1]
  local cmd = _1_[2]
  local desc = _1_[3]
  map(("<localleader>" .. k), cmd, desc)
end
map("]g", "CornelisNextGoal", "next goal")
map("[g", "CornelisPrevGoal", "previous goal")
map("<M-.>", "CornelisGoToDefinition", "go to definition")
map("gd", "CornelisGoToDefinition", "go to definition")
local group = vim.api.nvim_create_augroup("agda_info", {clear = false})
vim.api.nvim_clear_autocmds({group = group, buffer = 0})
return vim.api.nvim_create_autocmd("QuitPre", {group = group, buffer = 0, command = "silent! CornelisCloseInfoWindows"})
