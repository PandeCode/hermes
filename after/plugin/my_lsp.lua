---@type table<vim.lsp.protocol.Method, fun(params: table, callback:fun(err: lsp.ResponseError?, result: any))>
local handlers = {}
local ms = vim.lsp.protocol.Methods

---@param buf integer
---@return integer? client_id
local function start_lsp(buf)
	---@type vim.lsp.ClientConfig
	local client_cfg = {
		name = "dict-lsp",
		cmd = function()
			return {
				request = function(method, params, callback)
					if handlers[method] then
						handlers[method](params, callback)
					end
				end,
				notify = function() end,
				is_closing = function() end,
				terminate = function() end,
			}
		end,
	}

	return vim.lsp.start(client_cfg, { bufnr = buf, silent = false })
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown", "neorg", "org", "other", "txt" },
	callback = function(ev)
		start_lsp(ev.buf)
	end,
})

vim.keymap.set("n", "grr", function()
	local url = "https://dictionary.cambridge.org/thesaurus/%s"
	local word = vim.fn.expand("<cword>")
	vim.ui.open(string.format(url, word))
end)

---@type lsp.InitializeResult
local initializeResult = {
	capabilities = {
		hoverProvider = true,
		definitionProvider = true,
		referencesProvider = true,
		completionProvider = {
			triggerCharacters = (function()
				local chars = {}
				for i = 32, 126 do
					table.insert(chars, string.char(i))
				end
				return chars
			end)(),
		},
	},
	serverInfo = {
		name = "dict-lsp",
		version = "0.0.1",
	},
}

handlers[ms.initialize] = function(_, callback)
	callback(nil, initializeResult)
end

---@param _ lsp.HoverParams
---@param callback fun(err?: lsp.ResponseError, result: lsp.Hover)
handlers[ms.textDocument_hover] = function(_, callback)
	local word = vim.fn.expand("<cword>")
	local url_format = "https://api.dictionaryapi.dev/api/v2/entries/en/%s"

	vim.system(
		{ "curl", url_format:format(word) },
		vim.schedule_wrap(function(out)
			local contents
			if out.code ~= 0 then
				contents = "word fetch failed"
			else
				local ok, decoded = pcall(vim.json.decode, out.stdout)
				if ok and decoded and decoded[1] then
					contents = decoded[1].meanings[1].definitions[1].definition
				else
					contents = decoded.message -- this api gives a nice message if no result
				end
			end
			callback(nil, { contents = contents })
		end)
	)
end

handlers[ms.textDocument_definition] = function()
	local url = "https://dictionary.cambridge.org/dictionary/english/%s"
	local word = vim.fn.expand("<cword>")
	vim.ui.open(string.format(url, word))
end

handlers[ms.textDocument_references] = function()
	local url = "https://dictionary.cambridge.org/thesaurus/%s"
	local word = vim.fn.expand("<cword>")
	vim.ui.open(string.format(url, word))
end

---Adapted from none-ls
---gets word to complete for use in completion sources
---@param params lsp.CompletionParams
---@return string word_to_complete
local get_word_to_complete = function(params)
	local col = params.position.character + 1
	local line = vim.api.nvim_get_current_line()
	local line_to_cursor = line:sub(1, col)
	local regex = vim.regex("\\k*$")

	return line:sub(regex:match_str(line_to_cursor) + 1, col)
end

---@param params lsp.CompletionParams
---@param callback fun(err?: lsp.ResponseError, result: lsp.CompletionItem[])
handlers[ms.textDocument_completion] = function(params, callback)
	local word = get_word_to_complete(params)
	local get_candidates = function(entries)
		entries = vim.fn.matchfuzzy(entries, word, { limit = 7 })
		local items = {}
		for k, v in ipairs(entries) do
			items[k] = { label = v, kind = vim.lsp.protocol.CompletionItemKind["Text"] }
		end

		return items
	end

	local candidates = get_candidates(vim.fn.spellsuggest(word)) -- a real implementation queries a dictionary here

	candidates = vim.tbl_filter(function(candidate)
		return candidate.label:find("[ ']") == nil
	end, candidates)

	callback(nil, {
		items = candidates,
		isIncomplete = #candidates > 0,
	})
end
