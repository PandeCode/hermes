vim.lsp.enable("zls")

vim.keymap.set("n", "<leader>mr", require("utils").mk_ephemeral_term("zig build run"))
vim.keymap.set("n", "<leader>mt", require("utils").mk_ephemeral_term("zig build run -- -t"))
