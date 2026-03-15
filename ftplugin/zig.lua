local function zig_add_gpa()
  local node = vim.treesitter.get_node()
  return nil
end
vim.api.nvim_create_user_command("HermesZigAddGPA", zig_add_gpa, {})
vim.keymap.set("n", "<leader>za", zig_add_gpa, {desc = "Add Zig allocator param to current function"})
if (1 == vim.fn.filereadable("build.zig")) then
  vim.keymap.set("n", "<leader>mr", Utils.mk_tmp_term("zig build run"))
  return vim.keymap.set("n", "<leader>mt", Utils.mk_tmp_term("zig build run -- -t"))
else
  return nil
end
