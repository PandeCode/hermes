; (local M {})
;
; (set _G.StatusCol M)
;
; (fn M.get_signs []
;   "@return {name:string, text:string, texthl:string}[]"
;   (local buf (vim.api.nvim_win_get_buf vim.g.statusline_winid))
;   (vim.tbl_map #(. vim.fn.sign_getdefined 1)
;                (. (. (vim.fn.sign_getplaced buf {:group "*" :lnum vim.v.lnum})
;                      1) :signs)))
;
; ;; fnlfmt: skip
; (fn M.column []
;   (var sign nil)
;   (var git_sign nil)
;   (each [_ s (ipairs (M.get_signs))]
;     (if (s.name:find :GitSign) (set git_sign s) (set sign s)))
;   (.. (if sign (.. "%#" sign.texthl "#" sign.text  "%*") " ")
;       "%="
;       "%{&nu?(&rnu&&v:relnum?v:relnum:v:lnum):''} "
;       (if git_sign (.. "%#" git_sign.texthl "#" git_sign.text "%*") " ")))
;
; (set vim.opt.statuscolumn "%!v:lua.StatusCol.column()")
;
; M
