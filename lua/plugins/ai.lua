return {
	{
		"codecompanion.nvim",
		for_cat = "ai",
		on_plugin = { "nvim-treesitter", "nvim-lua/plenary.nvim", "saghen/blink.cmp" },

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
			vim.print("AI Loaded")
		end,
	},
}
