;; <leader>mr runs typst watch on the file and opens the pdf in zathura once
;; it is written. both are neovim's jobs, quitting neovim stops them. compile
;; errors fill the quickfix list, the statusline shows the two while they run.
;; <leader>mr again opens zathura if it was closed, or stops both
;;
;; <leader>mt toggles autosave for the buffer: it is written on every change
;; and on leaving insert mode, so typst watch compiles it. while autosave is on,
;; the errors of those compiles are held back until you save by hand or nothing
;; has been written for 10 seconds

(set vim.bo.errorformat (table.concat ["%f:%l:%c: %trror: %m"
                                       "%f:%l:%c: %tarning: %m"
                                       "%-G%.%#"]
                                      ","))

(local idle_ms 10000)

;; per buffer state that is not shown in the statusline: the last compile, the
;; hold timer and whether zathura was opened for this watch
(local states {})

(fn st [buf]
  (or (. states buf) (let [s {:lines []
                              :compiled false
                              :opened false
                              :viewed false
                              :typing false}]
                       (tset states buf s)
                       s)))

(fn alive? [job]
  (and job (= -1 (. (vim.fn.jobwait [job] 0) 1))))

(fn spawn [cmd opts]
  (let [job (vim.fn.jobstart cmd opts)]
    (if (> job 0) job (vim.notify (.. (. cmd 1) " did not start")
                                  vim.log.levels.ERROR))))

(fn pdf_of [buf]
  (.. (vim.fn.fnamemodify (vim.api.nvim_buf_get_name buf) ":p:r") :.pdf))

(fn set_status []
  (vim.cmd.redrawstatus {:bang true}))

(fn open_viewer [buf pdf]
  (tset vim.b buf :typst_viewer
        (spawn [:zathura pdf]
               {:on_exit #(when (vim.api.nvim_buf_is_valid buf)
                            (tset vim.b buf :typst_viewer nil)
                            (set_status))}))
  (set_status))

;; typst prints the paths relative to its cwd, made absolute here so a :cd
;; afterwards does not break the quickfix list
(fn absolute [line cwd]
  (pick-values 1
               (line:gsub "^([^/][^:]*)(:%d+:%d+: )"
                          (fn [path rest] (.. cwd "/" path rest)))))

;; puts the last compile's diagnostics in the quickfix list and opens zathura
;; after a clean compile. nothing happens while the result is held
(fn show [buf]
  (let [s (st buf)
        efm (. vim.bo buf :errorformat)
        title (.. "typst watch "
                  (vim.fn.fnamemodify (vim.api.nvim_buf_get_name buf) ":~:."))]
    (when (and s.compiled (not s.typing))
      (let [items (. (vim.fn.getqflist {:lines s.lines : efm}) :items)
            errors (accumulate [n 0 _ e (ipairs items)]
                     (if (= e.type :e) (+ n 1) n))
            mine (= title (. (vim.fn.getqflist {:title 0}) :title))]
        (tset vim.b buf :typst_errors errors)
        ;; a clean compile only clears our own list, not a grep from in between
        (when (or mine (> (length items) 0))
          (Utils.set_qf title s.lines efm))
        (if (and (> errors 0) (not s.opened))
            (do
              (set s.opened true)
              (vim.cmd "botright copen")
              (vim.cmd "wincmd p"))
            (and mine (= 0 (length items)))
            (vim.cmd.cclose))
        (when (and (= 0 errors) (not s.viewed)
                   (= 1 (vim.fn.filereadable (pdf_of buf))))
          (set s.viewed true)
          (open_viewer buf (pdf_of buf))))
      (set_status))))

;; an autosave write, or a change while held, keeps the results back. the
;; timer lets them through after 10 seconds without a write
(fn release [buf]
  (let [s (st buf)]
    (when s.timer (s.timer:stop))
    (set s.typing false)
    (show buf)))

(fn hold [buf]
  (let [s (st buf)]
    (set s.typing true)
    (when (not s.timer) (set s.timer (vim.uv.new_timer)))
    (s.timer:stop)
    (s.timer:start idle_ms 0 (vim.schedule_wrap #(release buf)))))

(fn autosave [buf]
  (when (and (. vim.b buf :typst_mode) (alive? (. vim.b buf :typst_watch))
             (. vim.bo buf :modified) (= "" (. vim.bo buf :buftype))
             (not= "" (vim.api.nvim_buf_get_name buf)))
    (hold buf)
    (tset vim.b buf :typst_autosaving true)
    (vim.cmd "silent! update")
    (tset vim.b buf :typst_autosaving nil)))

(fn start_watch [buf]
  (let [s (st buf)
        file (vim.api.nvim_buf_get_name buf)
        cwd (vim.fn.getcwd)]
    (var pending "")
    (set s.viewed false)
    (set s.typing false)

    (fn on_output [_ data]
      (tset data 1 (.. pending (. data 1)))
      (set pending (table.remove data))
      (each [_ line (ipairs data)]
        (if (line:find "^%[[%d:]+%] compiling")
            (do
              (set s.lines [])
              (set s.compiled false)
              (set s.opened false))
            (line:find "^%[[%d:]+%] compiled")
            (set s.compiled true)
            s.compiled
            (table.insert s.lines (absolute line cwd))))
      (when (and s.compiled (vim.api.nvim_buf_is_valid buf))
        (show buf)))

    (vim.cmd "silent! wall")
    (tset vim.b buf :typst_errors 0)
    (tset vim.b buf :typst_watch
          (spawn [:typst :watch :--diagnostic-format :short file]
                 {:on_stderr on_output
                  :on_exit #(when (vim.api.nvim_buf_is_valid buf)
                              (tset vim.b buf :typst_watch nil)
                              (set_status))}))))

(fn stop [buf]
  (each [_ name (ipairs [:typst_watch :typst_viewer])]
    (let [job (. vim.b buf name)]
      (when job (vim.fn.jobstop job)))))

(fn toggle []
  (let [buf (vim.api.nvim_get_current_buf)
        watch (alive? vim.b.typst_watch)
        viewer (alive? vim.b.typst_viewer)]
    (if (and watch viewer) (stop buf) watch
        (if (= 1 (vim.fn.filereadable (pdf_of buf)))
            (open_viewer buf (pdf_of buf))
            (vim.notify "no pdf yet" vim.log.levels.WARN))
        (start_watch buf))))

(fn toggle_autosave []
  (let [buf (vim.api.nvim_get_current_buf)]
    (if (. vim.b buf :typst_mode)
        (do
          (tset vim.b buf :typst_mode nil)
          (release buf))
        (tset vim.b buf :typst_mode true))
    (set_status)))

(fn unload [buf]
  (let [s (. states buf)]
    (when (and s s.timer)
      (s.timer:stop)
      (s.timer:close))
    (stop buf)
    (tset states buf nil)))

;; autocmd callbacks must not return a value: a truthy one deletes the autocmd
(fn quiet [f]
  (fn [args]
    (f args.buf)
    nil))

(local group (vim.api.nvim_create_augroup :typst_watch {:clear false}))
(vim.api.nvim_clear_autocmds {: group :buffer 0})
(vim.api.nvim_create_autocmd :BufUnload
                             {: group :buffer 0 :callback (quiet unload)})

(vim.api.nvim_create_autocmd [:TextChanged :InsertLeave]
                             {: group :buffer 0 :callback (quiet autosave)})

(vim.api.nvim_create_autocmd :BufWritePost
                             {: group
                              :buffer 0
                              :callback (fn [args]
                                          (when (not (. vim.b args.buf
                                                        :typst_autosaving))
                                            (release args.buf))
                                          nil)})

(vim.keymap.set :n :<leader>mr toggle
                {:buffer 0 :desc "typst watch and zathura"})

(vim.keymap.set :n :<leader>mt toggle_autosave
                {:buffer 0 :desc "typst autosave, holds errors while typing"})
