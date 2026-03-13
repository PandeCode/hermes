(vim.loader.enable)

; ((. (require :fennel) :install))

(include :fnl.options)
(include :fnl.keymaps)
(include :fnl.autocmds)

(include :fnl.plugins)

(include :fnl.theme)
(include :fnl.statusline)

;; https://www.reddit.com/r/neovim/comments/1jpbc7s/disable_virtual_text_if_there_is_diagnostic_in/

(vim.diagnostic.config {:virtual_text true
                        :virtual_lines {:current_line true}
                        :underline true
                        :update_in_insert false})

(local og_virt_text nil)
(local og_virt_line nil)

;; fnlfmt: skip
(lua "
 vim.api.nvim_create_autocmd({ \"CursorMoved\", \"DiagnosticChanged\" }, {
 	group = vim.api.nvim_create_augroup(\"diagnostic_only_virtlines\", {}),
 	callback = function()
 		if og_virt_line == nil then
 			og_virt_line = vim.diagnostic.config().virtual_lines
 		end

 		-- ignore if virtual_lines.current_line is disabled
 		if not (og_virt_line and og_virt_line.current_line) then
 			if og_virt_text then
 				vim.diagnostic.config({ virtual_text = og_virt_text })
 				og_virt_text = nil
 			end
 			return
 		end

 		if og_virt_text == nil then
 			og_virt_text = vim.diagnostic.config().virtual_text
 		end

 		local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1

 		if vim.tbl_isempty(vim.diagnostic.get(0, { lnum = lnum })) then
 			vim.diagnostic.config({ virtual_text = og_virt_text })
 		else
 			vim.diagnostic.config({ virtual_text = false })
 		end
 	end,
 })
")

(vim.api.nvim_create_autocmd :ModeChanged
                             {:group (vim.api.nvim_create_augroup :diagnostic_redraw
                                                                  {})
                              :callback #(pcall vim.diagnostic.show)})

;; fnlfmt: skip
(lua "
local wrap_format_stop_blocks = {
	{ \"lua\", \"-- stylua: ignore start\", \"-- stylua: ignore end\" },
	{ \"python\", \"# fmt: off\", \"# fmt: on\" },
	{ { \"haskell\", \"lhaskell\" }, \"{- ORMOLU_DISABLE -}\", \"{- ORMOLU_ENABLE -}\" },
	{ { \"cpp\", \"c\" }, \"// clang-format off\", \"// clang-format on\" },
}

local top_format_stop_blocks = {
	{
		{
			\"js\",
			\"ts\",
			\"tsx\",
			\"jsx\",
			\"vue\",
			\"json\",
			\"svelte\",
			\"javascript\",
			\"typescript\",
			\"javascriptreact\",
			\"typescriptreact\",
		},
		\"// prettier-ignore\",
	},
	{ \"rust\", \"#[rustfmt::skip]\" },
	{ \"fennel\", \";; fnlfmt: skip\" },
}

function add_wrap_format_stop_block(filetypes, start, stop)
	filetypes = type(filetypes) == \"table\" and filetypes or { filetypes }

	vim.api.nvim_create_autocmd(\"Filetype\", {
		pattern = filetypes,
		callback = function(tbl)
			vim.keymap.set(
				\"v\",
				\"<SPACE>fo\",
				\"vnoremap <buffer> <SPACE>fo <esc>`>a\" .. stop .. \"<esc>`<i\" .. start .. \"<esc>\",
				{ buffer = tbl.buf }
			)
		end,
	})

	vim.api.nvim_create_autocmd(\"Filetype\", {
		pattern = filetypes,
		callback = function(tbl)
			vim.keymap.set(\"n\", \"<SPACE>fo\", \"<esc>{o\" .. start .. \"<esc>}O\" .. stop .. \"<esc>\", { buffer = tbl.buf })
		end,
	})
end

function add_top_format_stop_block(filetypes, top)
	filetypes = type(filetypes) == \"table\" and filetypes or { filetypes }

	vim.api.nvim_create_autocmd(\"Filetype\", {
		pattern = filetypes,
		callback = function(tbl)
			vim.keymap.set(\"v\", \"<SPACE>fo\", \"<esc>`<i\" .. top .. \"<esc>\", { buffer = tbl.buf })
		end,
	})

	vim.api.nvim_create_autocmd(\"Filetype\", {
		pattern = filetypes,
		callback = function(tbl)
			vim.keymap.set(\"n\", \"<SPACE>fo\", \"<esc>{o\" .. top .. \"<esc>\", { buffer = tbl.buf })
		end,
	})
end

for _, wrap_format_stop_block in ipairs(wrap_format_stop_blocks) do
	add_wrap_format_stop_block(wrap_format_stop_block[1], wrap_format_stop_block[2], wrap_format_stop_block[3])
end

for _, top_format_stop_block in ipairs(top_format_stop_blocks) do
	add_top_format_stop_block(top_format_stop_block[1], top_format_stop_block[2])
end
     "

 )

nil
