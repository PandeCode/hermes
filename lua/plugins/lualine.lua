return {
	"lualine.nvim",
	event = "DeferredUIEnter",
	after = function(plugin)
		require("lualine").setup({
			options = {
				icons_enabled = false,
				component_separators = "|",
				section_separators = "",
			},
			sections = {
				lualine_c = {
					{
						"filename",
						path = 1,
						status = true,
					},
				},
			},
			inactive_sections = {
				lualine_b = {
					{
						"filename",
						path = 3,
						status = true,
					},
				},
				lualine_x = { "filetype" },
			},
			-- Bufferline does this
			-- tabline = {
			-- 	lualine_a = { "buffers" },
			-- 	lualine_z = { "tabs" },
			-- },
		})
	end,
}
