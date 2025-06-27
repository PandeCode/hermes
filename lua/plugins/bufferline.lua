return {
	"bufferline.nvim",
	keys = {
		{ "<LEADER>1", "<CMD>BufferLineGoToBuffer 1<CR>" },
		{ "<LEADER>2", "<CMD>BufferLineGoToBuffer 2<CR>" },
		{ "<LEADER>3", "<CMD>BufferLineGoToBuffer 3<CR>" },
		{ "<LEADER>4", "<CMD>BufferLineGoToBuffer 4<CR>" },
		{ "<LEADER>5", "<CMD>BufferLineGoToBuffer 5<CR>" },
		{ "<LEADER>6", "<CMD>BufferLineGoToBuffer 6<CR>" },
		{ "<LEADER>7", "<CMD>BufferLineGoToBuffer 7<CR>" },
		{ "<LEADER>8", "<CMD>BufferLineGoToBuffer 8<CR>" },
		{ "<LEADER>9", "<CMD>BufferLineGoToBuffer 9<CR>" },
	},
	after = function(plugin)
		require("bufferline").setup({
			options = {
				custom_areas = {
					right = function()
						local result = {}
						local seve = vim.diagnostic.severity
						local error = #vim.diagnostic.get(0, { severity = seve.ERROR })
						local warning = #vim.diagnostic.get(0, { severity = seve.WARN })
						local info = #vim.diagnostic.get(0, { severity = seve.INFO })
						local hint = #vim.diagnostic.get(0, { severity = seve.HINT })

						if error ~= 0 then
							table.insert(result, { text = "  " .. error, link = "DiagnosticError" })
						end

						if warning ~= 0 then
							table.insert(result, { text = "  " .. warning, link = "DiagnosticWarn" })
						end

						if hint ~= 0 then
							table.insert(result, { text = "  " .. hint, link = "DiagnosticHint" })
						end

						if info ~= 0 then
							table.insert(result, { text = "  " .. info, link = "DiagnosticInfo" })
						end
						return result
					end,
				},
				hover = {
					enabled = true,
					delay = 200,
					reveal = { "close" },
				},
				separator_style = "padded_slant",
				diagnostics_indicator = function(count, level, diagnostics_dict, context)
					if context.buffer:current() then
						return ""
					end

					local s = " "
					for e, n in pairs(diagnostics_dict) do
						local sym = e == "error" and " " or (e == "warning" and " " or " ")
						s = s .. n .. sym
					end
					return s
				end,
			},
		})
	end,
}
