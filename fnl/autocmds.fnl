; -- A per project shadafile
; -- https://www.reddit.com/r/neovim/comments/1hkpgar/a_per_project_shadafile/

(set vim.opt.shadafile ((fn []
                          (local data (vim.fn.stdpath :data))
                          (var cwd (vim.fn.getcwd))
                          (set cwd (or (vim.fs.root cwd :.git) cwd))
                          ;; a hash, base64 of a deep path is longer than a
                          ;; file name may be
                          (local file
                                 (vim.fs.joinpath data :project_shada
                                                  (vim.fn.sha256 cwd)))
                          (vim.fn.mkdir (vim.fs.dirname file) :p)
                          file)))

;; Return to last edit position when opening files (You want this!))
; autocmd BufReadPost *
;      \ if line("'\"") > 0 && line("'\"") <= line("$") |
;      \   exe "normal! g`\"" |
;      \ endif

;; autocmd callbacks below end in nil: returning a truthy value (vim.cmd and
;; vim.fn.execute return "", mkdir returns 1) deletes the autocmd after one run
(vim.api.nvim_create_autocmd :BufReadPost
                             {:callback #(let [line vim.fn.line]
                                           (when (and (> (line "'\"") 0)
                                                      (<= (line "'\"")
                                                          (line "$")))
                                             (vim.fn.execute "normal! g`\""))
                                           nil)})

(vim.api.nvim_create_autocmd :TextYankPost {:callback #(vim.hl.hl_op)})

;; Make parent folders if they don't exist, only for real files (not oil:// and
;; other buffers that write through a plugin)
(vim.api.nvim_create_autocmd :BufWritePre
                             {:pattern "*"
                              :callback (fn [args]
                                          (when (and (= (. vim.bo args.buf
                                                           :buftype)
                                                        "")
                                                     (not (args.match:find "://"
                                                                           1
                                                                           true)))
                                            (vim.fn.mkdir (vim.fn.fnamemodify args.match
                                                                              ":p:h")
                                                          :p))
                                          nil)})

(vim.api.nvim_create_autocmd :InsertEnter
                             {:pattern "*"
                              :callback #(set vim.opt.relativenumber false)})

(vim.api.nvim_create_autocmd :InsertLeave
                             {:pattern "*"
                              :callback #(set vim.opt.relativenumber true)})

;; with several files, load the last one and come back to the first. on
;; VimEnter, since filetype detection is still off while init runs
(vim.api.nvim_create_autocmd :VimEnter
                             {:nested true
                              :callback #(when (> (vim.fn.argc) 1)
                                           (vim.cmd "silent blast | silent bfirst")
                                           nil)})

(vim.api.nvim_create_user_command :Gitadd
                                  (fn []
                                    (local filename (vim.fn.expand "%"))
                                    (vim.cmd "!git add %")
                                    (vim.notify (.. "Git added '" filename "'")))
                                  {})

(vim.api.nvim_create_user_command :Chmodx
                                  (fn []
                                    (local filename (vim.fn.expand "%"))
                                    (vim.cmd "!chmod +x %")
                                    (vim.notify (.. "Given execution rights to '"
                                                    filename "'")))
                                  {})

(vim.api.nvim_create_user_command :Rmf #(vim.cmd "!rm -f %") {})

;; only expand when the abbreviation is the whole : command, so a W or E in
;; a search or a :s pattern stays as typed
(each [from to (pairs {:W :w
                       :Q :q
                       :WQ :wq
                       :Wq :wq
                       :WQA :wqa
                       :Wqa :wqa
                       :QA :qa
                       :Qa :qa
                       :E :e
                       :gitadd :Gitadd
                       :chmodx :Chmodx
                       :rmf :Rmf
                       :fnl :Fnl})]
  (vim.keymap.set :ca from
                  #(if (and (= (vim.fn.getcmdtype) ":")
                            (= (vim.fn.getcmdline) from))
                       to
                       from)
                  {:expr true}))

;; https://www.reddit.com/r/neovim/comments/1jpbc7s/disable_virtual_text_if_there_is_diagnostic_in/

(vim.diagnostic.config {:virtual_text true
                        :virtual_lines {:current_line true}
                        :underline true
                        :update_in_insert false})

(var og_virt_text nil)
(var og_virt_line nil)

(vim.api.nvim_create_autocmd [:CursorMoved :DiagnosticChanged]
                             {:group (vim.api.nvim_create_augroup :diagnostic_only_virtlines
                                                                  {})
                              :callback (fn []
                                          (when (= og_virt_line nil)
                                            (set og_virt_line
                                                 (. (vim.diagnostic.config)
                                                    :virtual_lines)))
                                          ;; ignore if virtual_lines.current_line is disabled
                                          (when (not (and og_virt_line
                                                          og_virt_line.current_line))
                                            (when og_virt_text
                                              (vim.diagnostic.config {:virtual_text og_virt_text})
                                              (set og_virt_text nil))
                                            (lua :return))
                                          (when (= og_virt_text nil)
                                            (set og_virt_text
                                                 (. (vim.diagnostic.config)
                                                    :virtual_text)))
                                          (local lnum
                                                 (- (. (vim.api.nvim_win_get_cursor 0)
                                                       1)
                                                    1))
                                          (if (vim.tbl_isempty (vim.diagnostic.get 0
                                                                                   {: lnum}))
                                              (vim.diagnostic.config {:virtual_text og_virt_text})
                                              (vim.diagnostic.config {:virtual_text false})))})

(vim.api.nvim_create_autocmd :ModeChanged
                             {:group (vim.api.nvim_create_augroup :diagnostic_redraw
                                                                  {})
                              :callback #(do
                                           (pcall vim.diagnostic.show)
                                           nil)})

;; a file called f or fe is a typo for a <leader>f map, delete it after the write
(vim.api.nvim_create_autocmd :BufWritePost
                             {:pattern [:f :fe]
                              :callback (fn [args]
                                          (vim.fn.delete args.match)
                                          nil)})
