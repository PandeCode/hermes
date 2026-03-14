(global Statusline {})

(fn get_attached_clients []
  (local buf_clients (vim.lsp.get_clients {:bufnr 0}))
  (if (= (length buf_clients) 0)
      "No client active"
      (do
        (local buf_ft vim.bo.filetype)
        (local buf_client_names [])
        (var num_client_names (length buf_client_names))
        (each [_ client (pairs buf_clients)]
          (set num_client_names (+ num_client_names 1))
          (set (. buf_client_names num_client_names) client.name))
        (let [(ok? null_ls) (pcall require :null-ls)]
          (when ok?
            (local sources (null_ls.get_sources))
            (each [_ source (ipairs sources)]
              (when source._validated
                (each [ft_name ft_active (pairs source.filetypes)]
                  (when (and (= ft_name buf_ft) ft_active)
                    (table.insert buf_client_names source.name)))))))
        (when (and (= :lisp buf_ft) (#false)) ; sbcl_running
          (table.insert buf_client_names :sbcl))
        (.. "[" (table.concat buf_client_names ", ") "]"))))

(macro shl [g s] ;  status highlight
  `(.. "%#" ,g "#" (tostring ,s) "%*"))

(macro sshl [g s] ; safe status highlight
  `(.. (if ,g (.. "%#" ,g "#") "") (or ,s "") "%*"))

(macro get-icon [t n]
  `(let [[icon# hl#] [(pick-values 2 (MiniIcons.get ,t ,n))]]
     (sshl hl# icon#)))

(lua "
local function lsp()
  local count = {}
  local levels = {
    errors = \"Error\",
    warnings = \"Warn\",
    info = \"Info\",
    hints = \"Hint\",
  }

  for k, level in pairs(levels) do
    count[k] = vim.tbl_count(vim.diagnostic.get(0, { severity = level }))
  end

  local errors = \"\"
  local warnings = \"\"
  local hints = \"\"
  local info = \"\"

  if count[\"errors\"] ~= 0 then
    errors = \" %#LspDiagnosticsSignError# \" .. count[\"errors\"]
  end
  if count[\"warnings\"] ~= 0 then
    warnings = \" %#LspDiagnosticsSignWarning# \" .. count[\"warnings\"]
  end
  if count[\"hints\"] ~= 0 then
    hints = \" %#LspDiagnosticsSignHint# \" .. count[\"hints\"]
  end
  if count[\"info\"] ~= 0 then
    info = \" %#LspDiagnosticsSignInformation# \" .. count[\"info\"]
  end

  return errors .. warnings .. hints .. info .. \"%#Normal#\"
end

  ")

(fn lsp []
  (local count {})
  (local levels {:errors :Error :warnings :Warn :info :Info :hints :Hint})
  (each [k level (pairs levels)]
    (set (. count k) (vim.tbl_count (vim.diagnostic.get 0 {:severity level}))))
  (var errors "")
  (var warnings "")
  (var hints "")
  (var info "")
  (if (not= (. count :errors) 0)
      (set errors (.. " %#DiagnosticSignError# " (. count :errors))))
  (if (not= (. count :warnings) 0)
      (set warnings (.. " %#DiagnosticSignWarn# " (. count :warnings))))
  (if (not= (. count :hints) 0)
      (set hints (.. " %#DiagnosticSignHint# " (. count :hints))))
  (if (not= (. count :info) 0)
      (set info (.. " %#DiagnosticSignInfo# " (. count :info))))
  (.. errors warnings hints info "%#Normal#"))

;; fnlfmt: skip
(fn git []
  (let [d vim.b.gitsigns_status_dict]
    (if d
        (.. " "
            d.head
            " "
            (if d.added   (if (> d.added 0)   (shl "GitSignsAdd"    (.. "+ " d.added   " ")) "") "")
            (if d.changed (if (> d.changed 0) (shl "GitSignsChange" (.. "~ " d.changed " ")) "") "")
            (if d.removed (if (> d.removed 0) (shl "GitSignsRemove" (.. "- " d.removed " ")) "") "")
            " ")
        "")))

(fn fun []
  (if (= 1 vim.g.parinfer_enabled) :infer ""))

;; fnlfmt: skip
(fn Statusline.active []
  (.. "%f "
      (fun)
      " "
      (lsp)
      " "
      (git)
      "%="
      (get_attached_clients)
      "%="
      " "
      (get-icon :os :nixos)
      " "
      (get-icon :file (or (vim.fn.expand "%") :default))
      " "
      "%{&filetype != '' ? &filetype : 'text'} "
      "[%P %l:%c]"))

(fn Statusline.inactive []
  (.. "" " %t"))

(local group (vim.api.nvim_create_augroup :Statusline {:clear true}))

; (vim.cmd.redrawstatus)

(vim.api.nvim_create_autocmd [:WinEnter :BufEnter]
                             {: group
                              :callback (fn []
                                          (set vim.opt_local.statusline
                                               "%!v:lua.Statusline.active()"))})

(vim.api.nvim_create_autocmd [:WinLeave :BufLeave]
                             {: group
                              :callback (fn []
                                          (set vim.opt_local.statusline
                                               "%!v:lua.Statusline.inactive()"))})

(vim.defer_fn (fn []
                (vim.cmd.redrawstatus)) 1000)

; refs: https://nuxsh.is-a.dev/blog/custom-nvim-statusline.html
