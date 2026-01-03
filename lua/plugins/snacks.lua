local function sk(c)
	return function()
		Snacks.picker[c]()
	end
end

return {
	"snacks.nvim",
	event = "UIEnter",

	keys = {
		{ "<leader>ff",      sk("files"),               desc = "Find Files" },
		{ "<leader>fr",      sk("grep"),                desc = "Grep" },
		{ "<leader>fm",      sk("marks"),               desc = "Marks" },
		{ "<leader>fn",      sk("man"),                 desc = "Man" },
		{ "<leader><space>", sk("smart"),               desc = "Smart Find Files" },
		{ "<leader>,",       sk("buffers"),             desc = "Buffers" },
		{ "<leader>ch",      sk("cliphist"),            desc = "cliphist" },

		{ "<leader>fll",     sk("loclist"),             desc = "loclist" },
		{ "<leader>fq",      sk("qflist"),              desc = "qflist" },

		{ "<leader>fld",     sk("lsp_declarations"),    desc = "lsp_declarations" },
		{ "<leader>fle",     sk("lsp_definitions"),     desc = "lsp_definitions" },
		{ "<leader>fli",     sk("lsp_implementations"), desc = "lsp_implementations" },
		{ "<leader>flr",     sk("lsp_references"),      desc = "lsp_references" },
		{ "<leader>fls",     sk("lsp_symbols"),         desc = "lsp_symbols" },

		{
			"<leader>se",
			function()
				Snacks.explorer()
			end,
			desc = "Buffers",
		},
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

		-- ---@type table<number, {token:lsp.ProgressToken, msg:string, done:boolean}[]>
		-- local progress = vim.defaulttable()
		-- vim.api.nvim_create_autocmd("LspProgress", {
		-- 	---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
		-- 	callback = function(ev)
		-- 		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		-- 		local value = ev.data.params.value --[[@as {percentage?: number, title?: string, message?: string, kind: "begin" | "report" | "end"}]]
		-- 		if not client or type(value) ~= "table" then
		-- 			return
		-- 		end
		-- 		local p = progress[client.id]
		--
		-- 		for i = 1, #p + 1 do
		-- 			if i == #p + 1 or p[i].token == ev.data.params.token then
		-- 				p[i] = {
		-- 					token = ev.data.params.token,
		-- 					msg = ("[%3d%%] %s%s"):format(
		-- 						value.kind == "end" and 100 or value.percentage or 100,
		-- 						value.title or "",
		-- 						value.message and (" **%s**"):format(value.message) or ""
		-- 					),
		-- 					done = value.kind == "end",
		-- 				}
		-- 				break
		-- 			end
		-- 		end
		--
		-- 		local msg = {} ---@type string[]
		-- 		progress[client.id] = vim.tbl_filter(function(v)
		-- 			return table.insert(msg, v.msg) or not v.done
		-- 		end, p)
		--
		-- 		local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
		-- 		vim.notify(table.concat(msg, "\n"), "info", {
		-- 			id = "lsp_progress",
		-- 			title = client.name,
		-- 			opts = function(notif)
		-- 				notif.icon = #progress[client.id] == 0 and " "
		-- 					or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
		-- 			end,
		-- 		})
		-- 	end,
		-- })
	end,
}
