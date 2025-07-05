local function get_attached_clients()
	-- Get active clients for current buffer
	local buf_clients = vim.lsp.get_clients({ bufnr = 0 })
	if #buf_clients == 0 then
		return "No client active"
	end
	local buf_ft = vim.bo.filetype
	local buf_client_names = {}
	local num_client_names = #buf_client_names

	-- Add lsp-clients active in the current buffer
	for _, client in pairs(buf_clients) do
		num_client_names = num_client_names + 1
		buf_client_names[num_client_names] = client.name
	end

	local null_ls_s, null_ls = pcall(require, "null-ls")
	if null_ls_s then
		local sources = null_ls.get_sources()
		for _, source in ipairs(sources) do
			if source._validated then
				for ft_name, ft_active in pairs(source.filetypes) do
					if ft_name == buf_ft and ft_active then
						table.insert(buf_client_names, source.name)
					end
				end
			end
		end
	end

	-- Add formatters (conform.nvim)
	local conform_success, conform = pcall(require, "conform")
	if conform_success then
		for _, formatter in pairs(conform.list_formatters_for_buffer(0)) do
			if formatter then
				num_client_names = num_client_names + 1
				buf_client_names[num_client_names] = formatter
			end
		end
	end

	local client_names_str = table.concat(buf_client_names, ", ")
	local language_servers = string.format("[%s]", client_names_str)

	return language_servers
end

return {
	"lualine.nvim",
	event = "DeferredUIEnter",
	on_plugin = { "nvim-web-devicons", "conform.nvim" },
	after = function(plugin)
		local attached_clients = {
			get_attached_clients,
			color = {
				gui = "bold",
			},
		}

		require("lualine").setup({
			options = {
				icons_enabled = true,
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
					attached_clients,
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
