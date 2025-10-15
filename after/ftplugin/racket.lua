local open_ephemeral_term = require("utils").open_ephemeral_term

pcall(vim.keymap.del, "n", "<leader>rr")
pcall(vim.keymap.del, "n", "<leader>rd")
pcall(vim.keymap.del, "n", "<leader>rt")

vim.keymap.set("n", "<leader>rr", function()
	local file = vim.fn.expand("%:p")
	if vim.fn.fnamemodify(file, ":e") == "rkt" then
		open_ephemeral_term(
			"racket " .. vim.fn.fnameescape(file) .. " 2>&1 | sed -E 's|/nix/store/[a-z0-9]{32}-|…/|g'"
		)
	else
		print("Not a .rkt file")
	end
end, { desc = "Run current Racket file (clean logs)" })

vim.keymap.set("n", "<leader>rt", function()
	local file = vim.fn.expand("%:p")
	if vim.fn.fnamemodify(file, ":e") == "rkt" then
		open_ephemeral_term(
			"raco test " .. vim.fn.fnameescape(file) .. " 2>&1 | sed -E 's|/nix/store/[a-z0-9]{32}-|…/|g'"
		)
	else
		print("Not a .rkt file")
	end
end, { desc = "Run current Racket test (clean logs)" })

vim.keymap.set("n", "<leader>rd", function()
	local file = vim.fn.expand("%:p")
	if vim.fn.fnamemodify(file, ":e") == "rkt" then
		vim.fn.jobstart({ "drracket", file }, { detach = true })
		print("Opened in DrRacket: " .. file)
	else
		print("Not a .rkt file")
	end
end, { desc = "Open current Racket file in DrRacket" })

vim.cmd("iabbrev lambda λ")

local null_ls = require("null-ls")
null_ls.register(null_ls.builtins.formatting.raco_fmt)

-- Define a command/keymap to open a Snacks picker with TODOs in the current file
vim.keymap.set("n", "<leader>td", function()
	local items = {}
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	for lnum, line in ipairs(lines) do
		if line:match("TODO:") then
			table.insert(items, {
				text = line,
				lnum = lnum,
				col = line:find("TODO:"),
			})
		end
	end

	require("snacks").picker({
		title = "TODOs",
		items = items,
		format_item = function(item)
			return string.format("%4d │ %s", item.lnum, item.text)
		end,
		on_select = function(item)
			vim.api.nvim_win_set_cursor(0, { item.lnum, item.col - 1 })
		end,
	})
end, { desc = "Pick TODOs in current file" })
