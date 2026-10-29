;; emacs agda-mode's C-c keys, on cornelis' commands. they work in insert
;; mode too, so a hole can be filled and given without leaving it. in insert
;; mode a lone <C-c> waits for the next key before it leaves insert mode
;;
;; <C-,> <C-.> and <C-Space> only reach neovim in a terminal with the kitty
;; keyboard protocol (ghostty, kitty), so each also has a plain-key twin.
;; agda-mode's C-c C-? is C-c ? here, neovim reads <C-?> as <Del>

(fn map [keys cmd desc]
  (each [_ k (ipairs (if (= (type keys) :table) keys [keys]))]
    (vim.keymap.set [:n :i] (.. :<C-c> k) (.. :<Cmd> cmd :<CR>)
                    {:buffer true :desc (.. "Agda: " desc)})))

;; fnlfmt: skip
(local bindings
  [[:<C-l> :CornelisLoad "load"]
   ["?" :CornelisGoals "goals"]
   [:<C-f> :CornelisNextGoal "next goal"]
   [:<C-b> :CornelisPrevGoal "previous goal"]
   [:<C-s> :CornelisSolve "solve constraints"]
   [:<C-x><C-r> :CornelisRestart "restart agda"]
   [:<C-x><C-a> :CornelisAbort "abort"]
   [[:<C-Space> :<Space>] :CornelisGive "give"]
   [:<C-r> :CornelisRefine "refine"]
   [:<C-m> :CornelisElaborate "elaborate and give"]
   [:<C-a> :CornelisAuto "auto"]
   [:<C-c> :CornelisMakeCase "case split"]
   [["<C-,>" ","] :CornelisTypeContext "goal type and context"]
   [["<C-.>" "."] :CornelisTypeContextInfer "goal type, context and inferred type"]
   [:<C-d> :CornelisTypeInfer "infer type"]
   [:<C-n> :CornelisNormalize "compute normal form"]
   [:<C-w> :CornelisWhyInScope "why in scope"]
   [:<C-h> :CornelisHelperFunc "helper function type"]])

(each [_ [k cmd desc] (ipairs bindings)]
  (map k cmd desc))

;; agda-mode's M-., and gd since als has no definitions
(each [_ k (ipairs [:<M-.> :gd])]
  (vim.keymap.set :n k :<Cmd>CornelisGoToDefinition<CR>
                  {:buffer true :desc "Agda: go to definition"}))

;; info windows would keep :q from closing the last agda window. ftplugins
;; run again when lz.n replays FileType, so the old autocmd goes first
(local group (vim.api.nvim_create_augroup :agda_info {:clear false}))
(vim.api.nvim_clear_autocmds {: group :buffer 0})
(vim.api.nvim_create_autocmd :QuitPre
                             {: group
                              :buffer 0
                              :command "silent! CornelisCloseInfoWindows"})
