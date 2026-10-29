local function map(keys, cmd, desc)
  local function _1_()
    if (type(keys) == "table") then
      return keys
    else
      return {keys}
    end
  end
  for _, k in ipairs(_1_()) do
    vim.keymap.set({"n", "i"}, ("<C-c>" .. k), ("<Cmd>" .. cmd .. "<CR>"), {buffer = true, desc = ("Agda: " .. desc)})
  end
  return nil
end
local bindings = {{"<C-l>", "CornelisLoad", "load"}, {"?", "CornelisGoals", "goals"}, {"<C-f>", "CornelisNextGoal", "next goal"}, {"<C-b>", "CornelisPrevGoal", "previous goal"}, {"<C-s>", "CornelisSolve", "solve constraints"}, {"<C-x><C-r>", "CornelisRestart", "restart agda"}, {"<C-x><C-a>", "CornelisAbort", "abort"}, {{"<C-Space>", "<Space>"}, "CornelisGive", "give"}, {"<C-r>", "CornelisRefine", "refine"}, {"<C-m>", "CornelisElaborate", "elaborate and give"}, {"<C-a>", "CornelisAuto", "auto"}, {"<C-c>", "CornelisMakeCase", "case split"}, {{"<C-,>", ","}, "CornelisTypeContext", "goal type and context"}, {{"<C-.>", "."}, "CornelisTypeContextInfer", "goal type, context and inferred type"}, {"<C-d>", "CornelisTypeInfer", "infer type"}, {"<C-n>", "CornelisNormalize", "compute normal form"}, {"<C-w>", "CornelisWhyInScope", "why in scope"}, {"<C-h>", "CornelisHelperFunc", "helper function type"}}
for _, _2_ in ipairs(bindings) do
  local k = _2_[1]
  local cmd = _2_[2]
  local desc = _2_[3]
  map(k, cmd, desc)
end
for _, k in ipairs({"<M-.>", "gd"}) do
  vim.keymap.set("n", k, "<Cmd>CornelisGoToDefinition<CR>", {buffer = true, desc = "Agda: go to definition"})
end
local group = vim.api.nvim_create_augroup("agda_info", {clear = false})
vim.api.nvim_clear_autocmds({group = group, buffer = 0})
return vim.api.nvim_create_autocmd("QuitPre", {group = group, buffer = 0, command = "silent! CornelisCloseInfoWindows"})
