local ai = vim.fn.getenv("AI")

if ai ~= vim.NIL then
	return {
		{
			"codecompanion.nvim",
			on_plugin = { "nvim-treesitter", "plenary.nvim", "blink.cmp" },

			before = function()
				vim.env["CODECOMPANION_TOKEN_PATH"] = vim.fn.expand("~/.config")
			end,
			after = function()
				require("codecompanion").setup({
					--Refer to: https://github.com/olimorris/codecompanion.nvim/blob/main/lua/codecompanion/config.lua
					strategies = {
						--NOTE: Change the adapter as required
						chat = { adapter = "copilot" },
						inline = { adapter = "copilot" },
					},
					opts = {
						log_level = "DEBUG",
					},
				})
				vim.print("ai Loaded")
			end,
		},
	}
else
	return {}
end
