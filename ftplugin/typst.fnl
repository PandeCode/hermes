;; <leader>mr runs typst watch on the file and opens the pdf in zathura once
;; it is written. both are neovim's jobs, quitting neovim stops them. compile
;; errors fill the quickfix list, the statusline shows the two while they run.
;; <leader>mr again opens zathura if it was closed, or stops both

(set vim.bo.errorformat (table.concat ["%f:%l:%c: %trror: %m"
                                       "%f:%l:%c: %tarning: %m"
                                       "%-G%.%#"]
                                      ","))

(fn alive? [job]
  (and job (= -1 (. (vim.fn.jobwait [job] 0) 1))))

(fn spawn [cmd opts]
  (let [job (vim.fn.jobstart cmd opts)]
    (if (> job 0) job
        (vim.notify (.. (. cmd 1) " did not start") vim.log.levels.ERROR))))

(fn open_viewer [buf pdf]
  (tset vim.b buf :typst_viewer
        (spawn [:zathura pdf]
               {:on_exit #(when (vim.api.nvim_buf_is_valid buf)
                            (tset vim.b buf :typst_viewer nil)
                            (vim.cmd.redrawstatus {:bang true}))}))
  (vim.cmd.redrawstatus {:bang true}))

;; typst prints the paths relative to its cwd, made absolute here so a :cd
;; afterwards does not break the quickfix list
(fn absolute [line cwd]
  (pick-values 1
               (line:gsub "^([^/][^:]*)(:%d+:%d+: )"
                          (fn [path rest] (.. cwd "/" path rest)))))

;; every compile prints `[time] compiling ...`, `[time] compiled ...` and
;; then its diagnostics, which can come in later chunks
(fn start_watch [buf]
  (let [file (vim.api.nvim_buf_get_name buf)
        pdf (.. (vim.fn.fnamemodify file ":r") :.pdf)
        cwd (vim.fn.getcwd)
        title (.. "typst watch " (vim.fn.fnamemodify file ":~:."))
        efm (. vim.bo buf :errorformat)]
    (var pending "")
    (var lines [])
    (var compiled false)
    (var opened false)
    (var viewed (alive? (. vim.b buf :typst_viewer)))

    ;; a clean compile only clears our own list, not a grep from in between
    (fn publish []
      (let [items (. (vim.fn.getqflist {: lines : efm}) :items)
            errors (accumulate [n 0 _ e (ipairs items)]
                     (if (= e.type :e) (+ n 1) n))
            mine (= title (. (vim.fn.getqflist {:title 0}) :title))]
        (tset vim.b buf :typst_errors errors)
        (when (or mine (> (length items) 0))
          (Utils.set_qf title lines efm))
        (if (> errors 0)
            (when (not opened)
              (set opened true)
              (vim.cmd "botright copen")
              (vim.cmd "wincmd p"))
            (and mine (= 0 (length items)))
            (vim.cmd.cclose)))
      ;; once, a closed zathura stays closed until <leader>mr
      (when (and (not viewed) (= 0 (. vim.b buf :typst_errors))
                 (= 1 (vim.fn.filereadable pdf)))
        (set viewed true)
        (open_viewer buf pdf))
      (vim.cmd.redrawstatus {:bang true}))

    (fn on_output [_ data]
      (tset data 1 (.. pending (. data 1)))
      (set pending (table.remove data))
      (each [_ line (ipairs data)]
        (if (line:find "^%[[%d:]+%] compiling")
            (do
              (set lines [])
              (set compiled false)
              (set opened false))
            (line:find "^%[[%d:]+%] compiled")
            (set compiled true)
            compiled
            (table.insert lines (absolute line cwd))))
      (when (and compiled (vim.api.nvim_buf_is_valid buf))
        (publish)))

    (vim.cmd "silent! wall")
    (tset vim.b buf :typst_errors 0)
    (tset vim.b buf :typst_watch
          (spawn [:typst :watch :--diagnostic-format :short file]
                 {:on_stderr on_output
                  :on_exit #(when (vim.api.nvim_buf_is_valid buf)
                              (tset vim.b buf :typst_watch nil)
                              (vim.cmd.redrawstatus {:bang true}))}))))

(fn stop [buf]
  (each [_ name (ipairs [:typst_watch :typst_viewer])]
    (let [job (. vim.b buf name)]
      (when job (vim.fn.jobstop job)))))

(fn toggle []
  (let [buf (vim.api.nvim_get_current_buf)
        watch (alive? vim.b.typst_watch)
        viewer (alive? vim.b.typst_viewer)
        pdf (.. (vim.fn.expand "%:p:r") :.pdf)]
    (if (and watch viewer) (stop buf)
        watch (if (= 1 (vim.fn.filereadable pdf))
                  (open_viewer buf pdf)
                  (vim.notify "no pdf yet" vim.log.levels.WARN))
        (start_watch buf))))

(local group (vim.api.nvim_create_augroup :typst_watch {:clear false}))
(vim.api.nvim_clear_autocmds {: group :buffer 0})
(vim.api.nvim_create_autocmd :BufUnload
                             {: group :buffer 0 :callback #(stop $1.buf)})

(vim.keymap.set :n :<leader>mr toggle
                {:buffer 0 :desc "typst watch and zathura"})
