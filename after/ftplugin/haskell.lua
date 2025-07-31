local ht = require("haskell-tools")

local bufnr = vim.api.nvim_get_current_buf()
local opts = { noremap = true, silent = true, buffer = bufnr }

require("lsps.on_attach")(_, bufnr)

local keymaps = {
	{ "<space>hs", ht.hoogle.hoogle_signature, opts, desc = "Hoogle search for type signature under cursor" },
	{ "<space>ea", ht.lsp.buf_eval_all, opts, desc = "Evaluate all code snippets" },
	{ "<leader>rr", ht.repl.toggle, opts, desc = "Toggle GHCi repl for current package" },
	{

		"<leader>rf",
		function()
			ht.repl.toggle(vim.api.nvim_buf_get_name(0))
		end,
		opts,
		desc = "Toggle GHCi repl for current buffer",
	},
	{ "<leader>rq", ht.repl.quit, opts, desc = "Quit GHCi repl" },
}

for _, map in ipairs(keymaps) do
	vim.keymap.set("n", map[1], map[2], vim.tbl_extend("force", map[3], { desc = map.desc }))
end

vim.print("Loaded haskell")
