(fn eval [c]
  (case vim.bo.ft
    ;; try it as an expression first, like the lua repl
    :lua (let [expr (loadstring (.. "return " c))
               (chunk err) (loadstring c)]
           ((assert (or expr chunk) err)))
    :vim (. (vim.api.nvim_exec2 c {:output true}) :output)
    :fennel (if Fennel (Fennel.eval c)
                (vim.notify "no Fennel" vim.log.levels.WARN))))

(fn eval_file []
  (case vim.bo.ft
    :lua (vim.cmd "luafile %")
    :vim (vim.cmd "source %")
    :fennel (eval (table.concat (vim.api.nvim_buf_get_lines 0 0 -1 false) "\n"))))

(fn eval_line []
  (eval (vim.api.nvim_get_current_line)))

;; '< and '> only update when visual mode ends, so read the live selection
(fn eval_blk []
  (let [lines (vim.fn.getregion (vim.fn.getpos :v) (vim.fn.getpos ".")
                                {:type (vim.fn.mode)})]
    (eval (table.concat lines "\n"))))

(vim.api.nvim_create_autocmd :FileType
                             {:pattern [:lua :fennel :vim]
                              :callback (fn []
                                          (vim.keymap.set :n :<leader>sf
                                                          eval_file
                                                          {:buffer true})
                                          (vim.keymap.set :n :<leader>ee
                                                          #(vim.notify (vim.inspect (eval_line)))
                                                          {:buffer true})
                                          (vim.keymap.set :v :<leader>ee
                                                          #(vim.notify (vim.inspect (eval_blk)))
                                                          {:buffer true}))})
