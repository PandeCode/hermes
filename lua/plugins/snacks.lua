local function sk(c)
	return function()
		Snacks.picker[c]()
	end
end
return {
	"snacks.nvim",
	event = "UIEnter",

	keys = {
		{ "<leader>ff", sk("files"), desc = "Find Files" },
		{ "<leader>fr", sk("grep"), desc = "Grep" },
		{ "<leader><space>", sk("smart"), desc = "Smart Find Files" },
		{ "<leader>,", sk("buffers"), desc = "Buffers" },
		{
			"<leader>nh",
			function()
				Snacks.notifier.hide()
			end,
			desc = "Notifier Hide",
		},
		{
			"<leader>nh",
			function()
				Snacks.notifier.show_history()
			end,
			desc = "Notifier Show",
		},
	},

	after = function()
		require("snacks").setup({
			bigfile = { enabled = true },
			dashboard = { enabled = false },
			explorer = { enabled = true },
			indent = { enabled = true },
			input = { enabled = true },
			picker = { enabled = true },
			notifier = { enabled = true },
			quickfile = { enabled = true },
			scope = { enabled = true },
			scroll = { enabled = true },
			statuscolumn = { enabled = true },
			words = { enabled = true },
		})
	end,
}
