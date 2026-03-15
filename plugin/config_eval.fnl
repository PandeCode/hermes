(fn eval [c]
  (case vim.bo.ft
    :lua (loadstring c)
    :vim (vim.cmd c)
    :fennel (if Fennel (Fennel.eval c)
                (vim.notify "no Fennel" vim.log.levels.WARN))))

(fn eval_file []
  (case vim.bo.ft
    :lua (vim.cmd "luafile %")
    :vim (vim.cmd "source %")
    :fennel (eval (table.concat (vim.api.nvim_buf_get_lines 0 0 -1 false) "\n"))))

(fn eval_line []
  (eval (vim.api.nvim_get_current_line)))

(fn eval_blk []
  (let [start (vim.api.nvim_buf_get_mark 0 "<")
        end (vim.api.nvim_buf_get_mark 0 ">")
        lines (vim.api.nvim_buf_get_lines 0 (- (. start 1) 1) (. end 1) false)]
    (eval (table.concat lines "\n"))))

(vim.api.nvim_create_autocmd :FileType
                             {:pattern [:lua :fennel :vim]
                              :callback (fn []
                                          (vim.keymap.set :n :<leader>sf
                                                          eval_file
                                                          {:buffer true})
                                          (vim.keymap.set :n :<leader>ee
                                                          #(vim.notify (eval_line))
                                                          {:buffer true})
                                          (vim.keymap.set :v :<leader>ee
                                                          #(vim.notify (eval_blk))
                                                          {:buffer true}))})
