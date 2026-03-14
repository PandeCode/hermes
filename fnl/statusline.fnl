(global Statusline {})

(fn sbcl-running? []
  (let [ps (io.popen "pidof sbcl")
        pids (ps:read)]
    (ps:close)
    (if pids
        (do
          (var found false)
          (each [_ pid (ipairs (vim.fn.split pids " ")) &until found]
            (let [(ok? args) (pcall vim.fn.readfile (.. :/proc/ pid :/cmdline))]
              (when (and ok?
                         (vim.endswith (or (. args 1) "") "start-vlime.lisp\n"))
                (set found pid))))
          found)
        false)))

(macro shl [g s]
  `(.. "%#" ,g "#" (tostring ,s) "%*"))

(macro sshl [g s]
  `(.. (if ,g (.. "%#" ,g "#") "") (or ,s "") "%*"))

(macro hl! [name opts]
  `(vim.api.nvim_set_hl 0 ,name ,opts))

(macro pal [k]
  `(. MiniBase16.config.palette ,k))

(macro get-icon [t n]
  `(let [[icon# hl#] [(pick-values 2 (MiniIcons.get ,t ,n))]]
     (sshl hl# icon#)))

(hl! :ParinferOn {:fg (pal :base0B) :bold true})
(hl! :ParinferOff {:fg (pal :base03)})

(fn get-attached-clients []
  (local buf_clients (vim.lsp.get_clients {:bufnr 0}))
  (if (= (length buf_clients) 0)
      "No client active"
      (do
        (local buf_ft vim.bo.filetype)
        (local buf_client_names [])
        (each [_ client (pairs buf_clients)]
          (table.insert buf_client_names client.name))
        (let [(ok? null_ls) (pcall require :null-ls)]
          (when ok?
            (each [_ source (ipairs (null_ls.get_sources))]
              (when source._validated
                (each [ft_name ft_active (pairs source.filetypes)]
                  (when (and (= ft_name buf_ft) ft_active)
                    (table.insert buf_client_names source.name)))))))
        (when (and (= :lisp buf_ft) (sbcl-running?))
          (table.insert buf_client_names :sbcl))
        (.. "[" (table.concat buf_client_names ", ") "]"))))

;; fnlfmt: skip
(fn lsp []
  (local count {})
  (local levels {:errors :Error :warnings :Warn :info :Info :hints :Hint})
  (each [k level (pairs levels)]
    (set (. count k) (vim.tbl_count (vim.diagnostic.get 0 {:severity level}))))
  (.. (if (not= (. count :errors)   0) (shl :DiagnosticSignError (.. " " (. count :errors)))   "")
      (if (not= (. count :warnings) 0) (shl :DiagnosticSignWarn  (.. " " (. count :warnings))) "")
      (if (not= (. count :hints)    0) (shl :DiagnosticSignHint  (.. " " (. count :hints)))    "")
      (if (not= (. count :info)     0) (shl :DiagnosticSignInfo  (.. " " (. count :info)))     "")
      "%#Normal#"))

;; fnlfmt: skip
(fn git []
  (let [d vim.b.gitsigns_status_dict]
    (if d
        (.. " " d.head " "
            (if (and d.added   (> d.added 0))   (shl :GitSignsAdd    (.. "+ " d.added   " ")) "")
            (if (and d.changed (> d.changed 0)) (shl :GitSignsChange (.. "~ " d.changed " ")) "")
            (if (and d.removed (> d.removed 0)) (shl :GitSignsRemove (.. "- " d.removed " ")) ""))
        "")))

(fn fun []
  (let [lisp? (vim.tbl_contains [:racket :lisp :fennel :scheme] vim.bo.filetype)
        (icon) (MiniIcons.get :filetype :scheme)]
    (if (= 1 vim.g.parinfer_enabled)
        (.. "%#ParinferOn#" icon " ()%*")
        (if lisp?
            (.. "%#ParinferOff#" icon " ()%*") ""))))

(fn mode []
  (let [modes {:n ["(・_・)" :base0D :base00]
               :i ["(っ•̀ω•́)っ" :base0B :base00]
               :v ["(ᗒᗨᗕ)" :base0E :base00]
               :V ["(ᗒᗨᗕ)━" :base0E :base00]
               "\022" ["(ᗒᗨᗕ)█" :base0E :base00]
               :c ["(ง •̀_•́)ง" :base0A :base00]
               :R ["(눈_눈)" :base08 :base00]}
        m (vim.fn.mode)
        p MiniBase16.config.palette
        [text fg bg] (or (. modes m) ["?" :base05 :base00])]
    (hl! :StatusLineMode {:fg (. p fg) :bg (. p bg) :bold true})
    (.. "%#StatusLineMode#" text "%*")))

(fn recording []
  (let [reg (vim.fn.reg_recording)]
    (if (= reg "") ""
        (shl :WarningMsg (.. " (•_•) @" reg)))))

(fn searchcount []
  (let [(ok? sc) (pcall vim.fn.searchcount)]
    (if (and ok? sc.total (> sc.total 0))
        (.. "%#Comment#[" sc.current "/" sc.total "]%*")
        "")))

(local spinner-frames ["⠋"
                       "⠙"
                       "⠹"
                       "⠸"
                       "⠼"
                       "⠴"
                       "⠦"
                       "⠧"
                       "⠇"
                       "⠏"])

(fn lsp-progress []
  (let [clients (vim.lsp.get_clients {:bufnr 0})]
    (var spinning false)
    (each [_ client (ipairs clients)]
      (when (not (vim.tbl_isempty (or client.progress {})))
        (set spinning true)))
    (if spinning
        (let [frame (% (math.floor (* (vim.fn.reltimefloat (vim.fn.reltime)) 10))
                       (length spinner-frames))]
          (shl :Comment (. spinner-frames (+ frame 1))))
        "")))

(fn wordcount []
  (if (vim.tbl_contains [:markdown :text :org] vim.bo.filetype)
      (shl :Comment (.. " " (. (vim.fn.wordcount) :words) :w))
      ""))

(fn nix-shell []
  (let [env (os.getenv :IN_NIX_SHELL)]
    (if env (.. (get-icon :os :nixos) (shl :Comment env)) "")))

(fn filename []
  (let [buf (vim.api.nvim_buf_get_name 0)
        rel (vim.fn.fnamemodify buf ":~:.")
        name (vim.fn.fnamemodify buf ":t")
        dir (vim.fn.fnamemodify rel ":h")
        (icon hl) (MiniIcons.get :file name)]
    (.. "%#Comment#" (if (= dir ".") "" (.. dir "/")) "%*"
        (sshl hl (.. icon " " name)) " "
        (if vim.bo.modified (shl :WarningMsg "●") "")
        (if vim.bo.readonly (shl :DiagnosticError "🔒") ""))))

;; fnlfmt: skip
(fn Statusline.active []
  (.. (mode)
      " "
      (recording)
      " "
      (git)
      " "
      (filename)
      " "
      (fun)
      " "
      (lsp)
      "%="
      (lsp-progress)
      " "
      (searchcount)
      "%="
      (wordcount)
      " "
      (nix-shell)
      " "
      (get-icon :file (or (vim.fn.expand "%") :default))
      " "
      "%{&filetype != '' ? &filetype : 'text'} "
      (get-attached-clients)
      " "
      "[%P %l:%c]"))

(fn Statusline.inactive []
  (.. "%#Comment# %t%*"))

(local group (vim.api.nvim_create_augroup :Statusline {:clear true}))

(vim.api.nvim_create_autocmd [:WinEnter :BufEnter]
                             {: group
                              :callback #(set vim.opt_local.statusline
                                              "%!v:lua.Statusline.active()")})

(vim.api.nvim_create_autocmd [:WinLeave :BufLeave]
                             {: group
                              :callback #(set vim.opt_local.statusline
                                              "%!v:lua.Statusline.inactive()")})

(vim.defer_fn #(vim.cmd.redrawstatus) 1000)
