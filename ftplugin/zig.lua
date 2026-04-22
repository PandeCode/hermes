local function zig_add_gpa()
  local node = vim.treesitter.get_node()
  return nil
end
vim.api.nvim_create_user_command("HermesZigAddGPA", zig_add_gpa, {})
return vim.keymap.set("n", "<leader>za", zig_add_gpa, {desc = "Add Zig allocator param to current function"})
