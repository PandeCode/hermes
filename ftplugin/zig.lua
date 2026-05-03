local function zig_add_gpa()
  local node = vim.treesitter.get_node()
  return nil
end
vim.api.nvim_create_user_command("HermesZigAddGPA", zig_add_gpa, {})
vim.keymap.set("n", "<leader>za", zig_add_gpa, {desc = "Add Zig allocator param to current function"})
vim.g.zig_fmt_parse_errors = 0
vim.g.zig_fmt_autosave = 0
local function _1_(_)
  vim.lsp.buf.code_action({context = {only = {"source.fixAll"}}, apply = true})
  return vim.lsp.buf.code_action({context = {only = {"source.organizeImports"}}, apply = true})
end
vim.api.nvim_create_autocmd("BufWritePre", {pattern = {"*.zig", "*.zon"}, callback = _1_})
vim.lsp.config.zls = {settings = {zls = {enable_build_on_save = true, inlay_hints_hide_redundant_param_names = true, inlay_hints_hide_redundant_param_names_last_token = true, warn_style = true, highlight_global_var_declarations = true, build_on_save_args = {"-fincremental", "-j4"}}}}
return nil
