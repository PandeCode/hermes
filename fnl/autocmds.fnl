; -- A per project shadafile
; -- https://www.reddit.com/r/neovim/comments/1hkpgar/a_per_project_shadafile/

(set vim.opt.shadafile ((fn []
                          (local data (vim.fn.stdpath :data))
                          (var cwd (vim.fn.getcwd))
                          (set cwd (or (vim.fs.root cwd :.git) cwd))
                          (local cwd_b64 (vim.base64.encode cwd))
                          (local file
                                 (vim.fs.joinpath data :project_shada cwd_b64))
                          (vim.fn.mkdir (vim.fs.dirname file) :p)
                          file)))

;; Return to last edit position when opening files (You want this!))
; autocmd BufReadPost *
;      \ if line("'\"") > 0 && line("'\"") <= line("$") |
;      \   exe "normal! g`\"" |
;      \ endif

(vim.api.nvim_create_autocmd :BufReadPost
                             {:callback #(let [line vim.fn.line]
                                           (when (and (> (line "'\"") 0)
                                                      (<= (line "'\"")
                                                          (line "$")))
                                             (vim.fn.execute "normal! g`\"")))})

(vim.api.nvim_create_autocmd [:BufEnter :BufWrite :BufWritePost :BufRead]
                             {:callback #(pcall vim.treesitter.start)})

(vim.api.nvim_create_autocmd :TextYankPost {:callback vim.hl.on_yank})

;; Make parent folders if they don't exist
(vim.api.nvim_create_autocmd :BufWritePre
                             {:pattern "*"
                              :callback #(vim.fn.mkdir (vim.fn.expand "<afile>:p:h")
                                                       :p)})

(set vim.opt.number true)
(set vim.opt.relativenumber true)

(vim.api.nvim_create_autocmd :InsertEnter
                             {:pattern "*"
                              :callback #(set vim.opt.relativenumber false)})

(vim.api.nvim_create_autocmd :InsertLeave
                             {:pattern "*"
                              :callback #(set vim.opt.relativenumber true)})

;; fnlfmt: skip
(vim.cmd "
if argc() > 1
	silent blast \" load last buffer
	silent bfirst \" switch back to the first
endif

if exists('+termguicolors')
	let &t_8f=\"\\<Esc>[38;2;%lu;%lu;%lum\"
	let &t_8b=\"\\<Esc>[48;2;%lu;%lu;%lum\"
	set termguicolors
endif

syntax sync minlines=256

\" Allow saving of files as sudo when I forgot to start vim using sudo.
cnoremap w!! execute 'write !sudo tee % >/dev/null' <bar> edit!
")

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

;; fnlfmt: skip
(vim.cmd "
cnoreabbrev W w
cnoreabbrev Q q
cnoreabbrev WQ wq
cnoreabbrev Wq wq
cnoreabbrev WQA wqa
cnoreabbrev Wqa wqa
cnoreabbrev QA qa
cnoreabbrev Qa qa
cnoreabbrev E e
cnoreabbrev gitadd Gitadd
cnoreabbrev chmodx Chmodx
cnoreabbrev rmf Rmf
")

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
                              :callback #(pcall vim.diagnostic.show)})

(local bad-names ["^:w$" "^:wq$" :^f$ :^fe$])

(fn bad-name? [name]
  (accumulate [found false _ pat (ipairs bad-names) &until found]
    (not= nil (name:match pat))))

(vim.api.nvim_create_autocmd :BufWritePre
                             {:pattern "*"
                              :callback (fn []
                                          (let [name (vim.fn.expand "%:t")]
                                            (when (bad-name? name)
                                              (vim.notify (.. "Blocked: refusing to save file named "
                                                              " .. name .. " "")
                                                          vim.log.levels.ERROR)
                                              (vim.api.nvim_feedkeys (vim.api.nvim_replace_termcodes :<Esc>
                                                                                                     true
                                                                                                     false
                                                                                                     true)
                                                                     :n false))))})
