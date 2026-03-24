(vim.api.nvim_create_autocmd [:TermRequest :ModeChanged]
                             {:desc "Refresh tabline"
                              :callback #(vim.cmd.redrawtabline)})

(global Tabline {})

(let [p MiniBase16.config.palette]
  (vim.api.nvim_set_hl 0 :TabActive {:fg p.base00 :bg p.base0D :bold true})
  (vim.api.nvim_set_hl 0 :TabInactive {:fg p.base03 :bg p.base01})
  (vim.api.nvim_set_hl 0 :TabModified {:fg p.base08 :bg p.base01})
  (vim.api.nvim_set_hl 0 :TabLocked {:fg p.base09 :bg p.base01}))

(fn listed-bufs []
  (vim.tbl_filter (fn [b]
                    (and (vim.api.nvim_buf_is_valid b)
                         (= 1 (vim.fn.buflisted b))
                         (not= (vim.api.nvim_buf_get_name b) "")))
                  (vim.api.nvim_list_bufs)))

(fn buf-diag [buf]
  (let [e (length (vim.diagnostic.get buf
                                      {:severity vim.diagnostic.severity.ERROR}))
        w (length (vim.diagnostic.get buf
                                      {:severity vim.diagnostic.severity.WARN}))]
    (.. (if (> e 0) (.. "%#DiagnosticSignError# " e "%*") "")
        (if (> w 0) (.. "%#DiagnosticSignWarn# " w "%*") ""))))

(fn workspace-diag []
  (let [e (length (vim.diagnostic.get nil
                                      {:severity vim.diagnostic.severity.ERROR}))
        w (length (vim.diagnostic.get nil
                                      {:severity vim.diagnostic.severity.WARN}))
        h (length (vim.diagnostic.get nil
                                      {:severity vim.diagnostic.severity.HINT}))
        i (length (vim.diagnostic.get nil
                                      {:severity vim.diagnostic.severity.INFO}))]
    (.. (if (> e 0) (.. "%#DiagnosticSignError# " e "%*") "")
        (if (> w 0) (.. "%#DiagnosticSignWarn# " w "%*") "")
        (if (> h 0) (.. "%#DiagnosticSignHint# " h "%*") "")
        (if (> i 0) (.. "%#DiagnosticSignInfo# " i "%*") ""))))

(fn Tabline.goto [n]
  (let [buf (. (listed-bufs) n)]
    (when buf (vim.api.nvim_set_current_buf buf))))

(macro shl [g s]
  `(.. "%#" ,g "#" (tostring ,s) "%*"))

(fn Tabline.render []
  (let [current (vim.api.nvim_get_current_buf)
        bufs (listed-bufs)]
    (var result "")
    (each [i buf (ipairs bufs)]
      (let [name (vim.fn.fnamemodify (vim.api.nvim_buf_get_name buf) ":t")
            (icon hl) (MiniIcons.get :file name)
            modified (= 1 (vim.fn.getbufvar buf :&modified))
            readonly (= 1 (vim.fn.getbufvar buf :&readonly))
            nowrite (not vim.bo.modifiable)
            locked (or readonly nowrite)
            active (= buf current)
            hl (if active :TabActive
                   locked :TabLocked
                   modified :TabModified
                   :TabInactive)
            status (if locked " 󰌾"
                       modified " ●"
                       " ")]
        (set result (.. (shl hl icon) result "%#" hl "# "
                        (if (<= i 9) (.. i ":") "") " " name status "%*"
                        (buf-diag buf)))))
    (.. result "%=%#TabLineFill# " (workspace-diag) " ")))

(set vim.o.tabline "%!v:lua.Tabline.render()")
(set vim.o.showtabline 2)
(set _G.Tabline Tabline)

(for [i 1 9]
  (vim.keymap.set :n (.. :<leader> i) #(Tabline.goto i)
                  {:desc (.. "Go to buffer " i)}))

(fn tabline-update []
  (let [bufs (listed-bufs)]
    (set vim.o.showtabline (if (> (length bufs) 1) 2 0))))

(vim.api.nvim_create_autocmd [:BufAdd :BufDelete :BufEnter]
                             {:callback #(tabline-update)})

(vim.keymap.set :n :<leader>tt
                #(if (= vim.o.showtabline 2)
                     (set vim.o.showtabline 0)
                     (tabline-update)) {:desc "Toggle tabline"})
