;; emacs agda-mode's keys on cornelis' commands, with <localleader> for C-c and
;; without the C-: C-c C-l is \l. normal mode only, in insert mode \ starts
;; cornelis' unicode input

(fn map [lhs cmd desc]
  (vim.keymap.set :n lhs (.. :<Cmd> cmd :<CR>)
                  {:buffer true :desc (.. "Agda: " desc)}))

;; fnlfmt: skip
(local bindings
  [[:l :CornelisLoad "load"]
   ["?" :CornelisGoals "goals"]
   [:s :CornelisSolve "solve constraints"]
   [:xr :CornelisRestart "restart agda"]
   [:xa :CornelisAbort "abort"]
   [:<Space> :CornelisGive "give"]
   [:r :CornelisRefine "refine"]
   [:m :CornelisElaborate "elaborate and give"]
   [:a :CornelisAuto "auto"]
   [:c :CornelisMakeCase "case split"]
   ["," :CornelisTypeContext "goal type and context"]
   ["." :CornelisTypeContextInfer "goal type, context and inferred type"]
   [:d :CornelisTypeInfer "infer type"]
   [:n :CornelisNormalize "compute normal form"]
   [:w :CornelisWhyInScope "why in scope"]
   [:h :CornelisHelperFunc "helper function type"]])

(each [_ [k cmd desc] (ipairs bindings)]
  (map (.. :<localleader> k) cmd desc))

(map "]g" :CornelisNextGoal "next goal")
(map "[g" :CornelisPrevGoal "previous goal")

;; agda-mode's M-., and gd since als has no definitions
(map :<M-.> :CornelisGoToDefinition "go to definition")
(map :gd :CornelisGoToDefinition "go to definition")

;; info windows would keep :q from closing the last agda window. ftplugins
;; run again when lz.n replays FileType, so the old autocmd goes first
(local group (vim.api.nvim_create_augroup :agda_info {:clear false}))
(vim.api.nvim_clear_autocmds {: group :buffer 0})
(vim.api.nvim_create_autocmd :QuitPre
                             {: group
                              :buffer 0
                              :command "silent! CornelisCloseInfoWindows"})
