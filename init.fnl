(vim.loader.enable)

; ((. (require :fennel) :install))

(include :fnl.utils)

(include :fnl.options)
(include :fnl.keymaps)
(include :fnl.autocmds)

(include :fnl.plugins)

(include :fnl.theme)
(include :fnl.statusline)
(include :fnl.tabline)

(include :fnl.dap)

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
     ")

(fn eval-lua [code]
  (let [(ok? result) (pcall (fn []
                              (let [f (or (loadstring (.. "return " code))
                                          (loadstring code))]
                                (if f (vim.inspect (f)) "failed to load"))))]
    (if ok? result (tostring result))))

(fn eval-fennel [code]
  (case (pcall require :fennel)
    (true fennel) (case (pcall fennel.eval code)
                    (true result) (vim.inspect result)
                    (false err) (tostring err))
    (false _) "fennel not available"))

(fn get-visual-text []
  (let [start (vim.fn.getpos "'<")
        end (vim.fn.getpos "'>")
        lines (vim.api.nvim_buf_get_lines 0 (- (. start 2) 1) (. end 2) false)]
    (table.concat lines "\n")))

(fn get-fennel-form []
  (var target (vim.treesitter.get_node))
  (var parent (and target (target:parent)))
  (while (and parent (not= (parent:type) :program))
    (set target parent)
    (set parent (parent:parent)))
  (when target
    (let [start-row (target:start)
          end-row (target:end)
          lines (vim.api.nvim_buf_get_lines 0 start-row (+ end-row 1) false)]
      (table.concat lines "\n"))))

(fn eval-and-notify [evalfn code]
  (vim.notify (if code (evalfn code) "nothing to eval")))

(local ft-eval
       {:lua {:n #(eval-and-notify eval-lua (vim.fn.getreg "\""))
              :v #(eval-and-notify eval-lua (get-visual-text))}
        :fennel {:n #(eval-and-notify eval-fennel (get-fennel-form))
                 :v #(eval-and-notify eval-fennel (get-visual-text))}})

(fn eval-dispatch [mode]
  (let [ft vim.bo.filetype
        fns (. ft-eval ft)]
    (if fns
        ((. fns mode))
        (vim.notify (.. "no eval for filetype: " ft)))))

(vim.keymap.set :n :<leader>ee #(eval-dispatch :n) {:desc :Eval})
(vim.keymap.set :v :<leader>ee #(eval-dispatch :v) {:desc "Eval selection"})

nil
