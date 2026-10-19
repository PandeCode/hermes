(fn curry [f n ?args]
  "
WARN do not use directly. Use
```fennel
(defcurry)
````

```fennel
(defcurry tri-plus [a b c] (+ a b c)) ; nil
(tri-plus 1) ; #<function: 0x55ada32d3430>
((tri-plus 1) 2) ; #<function: 0x55ada3232260>
(((tri-plus 1) 2) 3) ; 6
((tri-plus 1 2) 3) ; 6
((tri-plus 1) 2 3) ; 6
```"
  (let [args (or ?args {:n 0})]
    (fn [...]
      (let [inner (table.pack ...)
            n* (+ args.n inner.n)]
        (doto inner
          (table.move 1 inner.n (+ args.n 1))
          (tset :n n*))
        (table.move args 1 args.n 1 inner)
        (if (>= n* n)
            (f ((or _G.unpack table.unpack) inner 1 n*))
            (curry f n inner))))))

(macro defcurry [name arglist ...]
  `(local ,name (curry (fn ,arglist ,...)
                       ,(length (icollect [_ a (ipairs arglist)
                                           :until (= (tostring a) "...")]
                                  a)))))

; https://dev.fennel-lang.org/wiki/CookbookRangeIterator

;; stateless iterator function, used as first return value from range fn bellow
(fn range-next* [[start end step] x]
  (if (= step 0) (when (not= start end) x)
      (let [x (+ x step)]
        (when (or (and (< 0 step) (< x end)) (and (> 0 step) (> x end)))
          x))))

(fn range [...]
  "Create a Lua iterator from ?start to ?end (non-inclusive); increment by ?step
When ?step is omitted, defaults to 1
When ?end is omitted, (range x) is identical to (range 0 x 1)
When (= ?step 0), infinitely repeats ?start
When (= ?start ?end), returns an empty iterator
```fennel
(icollect [v (range) :until (= v 10)] v) ; => [0 1 2 3 4 5 6 7 8 9]
(icollect [v (range 10)] v)              ; => [0 1 2 3 4 5 6 7 8 9]
(icollect [v (range 1 5)] v)             ; => [1 2 3 4]
(icollect [v (range 1 -5)] v)            ; => []
(icollect [v (range -1 5)] v)            ; => [-1 0 1 2 3 4]
(icollect [v (range -1 -5)] v)           ; => []
(icollect [v (range -5 -1)] v)           ; => [-5 -4 -3 -2]
(icollect [v (range -5 -1 -1)] v)        ; => []
(icollect [v (range -1 -5 -1)] v)        ; => [-1 -2 -3 -4

(do (var n 0)
    (icollect [v (range -1 -5 0)
               :until (= n 10)]
      (do (set n (+ n 1))
          v)))                   ; => [-1 -1 -1 -1 -1 -1 -1 -1 -1 -1

(do (var n 0)
    (icollect [v (range -5 -1 0)
               :until (= n 10)]
      (do (set n (+ n 1))
          v)))                   ; => [-5 -5 -5 -5 -5 -5 -5 -5 -5 -5

(do (var n 0)
    (icollect [v (range -5 0 0)
               :until (= n 10)]
      (do (set n (+ n 1))
          v)))                   ; => [-5 -5 -5 -5 -5 -5 -5 -5 -5 -5

(icollect [v (range 0)] v)       ; => []
(icollect [v (range 0 0)] v)     ; => []
(icollect [v (range 0 0 0)] v)   ; => [
```
"
  {:fnl/arglist [?start ?end ?step]}
  (let [(start end step) (case (values (select "#" ...) ...)
                           (0) (values 0 (/ 1 0) 1)
                           (1 ?end) (values 0 ?end 1)
                           (2 ?start ?end) (values ?start ?end 1)
                           _ ...)]
    (values range-next* [start end step] (- start step))))

;; fnlfmt: skip
(set Utils {})

(fn Utils.open_tmp_term [cmd fb]
  (vim.cmd (.. "botright split | terminal " cmd))
  (local bufnr (vim.api.nvim_win_get_buf 0))
  (vim.api.nvim_set_option_value :buflisted false {:buf bufnr})
  (vim.api.nvim_set_option_value :bufhidden :wipe {:buf bufnr})
  (local h (math.floor (/ vim.o.lines 4)))
  (vim.cmd (.. "resize " h))
  (vim.cmd "wincmd p")
  (when (not= fb nil) (fb bufnr)))

(fn Utils.bind_term [bind cmd fb]
  (vim.keymap.set :n bind #(Utils.open_tmp_term cmd fb)))

(fn Utils.bind_job [bind cmd]
  (vim.keymap.set :n bind #(vim.fn.jobstart [:sh :-c cmd])))

(fn Utils.bind_tmux [bind cmd]
  (Utils.bind_job bind
                  (.. "tmux split-window -l 10 '" cmd
                      " && exit 0 || tmux last-pane & tmux copy-mode & cat'; tmux last-pane")))

(Utils.bind_term :<leader>to "tmux kill-pane -a")

(fn table_keys [tbl]
  (local keys [])
  (var n 0)
  (each [key _ (pairs tbl)]
    (set n (+ n 1))
    (set (. keys n) key))
  keys)

(fn def_ui [tbl opts?]
  (vim.ui.select (table_keys tbl) (or opts? {})
                 (fn [choice]
                   (when choice
                     ((. tbl choice))))))

;; <leader>mb builds into the quickfix list, <leader>mr builds the same way and
;; runs the program in a terminal when the build passes, <leader>mt runs the
;; test under the cursor (or all of them) into the quickfix list. a filetype
;; sets vim.b.build_cmd, vim.b.run_cmd and vim.b.test_cmd, a .nvimrc.fnl
;; overrides them for the project with vim.g.*. errors are read with the
;; buffer's errorformat
(fn cmd_for [name]
  (or (. vim.g name) (. vim.b name)))

;; lines kept as text (a panic message, a failed test's name) come back from
;; the errorformat as valid entries with no file. marked as text, ]q goes from
;; one location to the next without stopping on them
(fn Utils.set_qf [title lines efm]
  (vim.fn.setqflist [] " " {: title : lines : efm})
  (vim.fn.setqflist [] :r {:items (icollect [_ e (ipairs (vim.fn.getqflist))]
                                    (do
                                      (when (= e.bufnr 0) (set e.valid 0))
                                      e))}))

(fn Utils.build [on_ok cmd?]
  (let [cmd (or cmd? (cmd_for :build_cmd))
        efm (vim.api.nvim_get_option_value :errorformat {})]
    (if (not cmd)
        (when on_ok (on_ok))
        (do
          (vim.cmd "silent! wall")
          (vim.notify cmd)
          ;; paths in the output are relative to the cwd, so the build runs
          ;; in neovim's like :make does
          (vim.system [:sh :-c (vim.fn.expandcmd cmd)] {:text true}
                      (vim.schedule_wrap (fn [out]
                                           (local output
                                                  (.. out.stdout out.stderr))
                                           (Utils.set_qf cmd
                                                         (vim.split output "\n")
                                                         efm)
                                           (if (= out.code 0)
                                               (do
                                                 (vim.cmd.cclose)
                                                 (if on_ok (on_ok)
                                                     (vim.notify (.. cmd " ok"))))
                                               (= 0 (length (vim.fn.getqflist)))
                                               ;; failed before compiling, a missing build file and the like
                                               (vim.notify output
                                                           vim.log.levels.ERROR)
                                               (vim.cmd "botright copen")))))))))

;; a program that dies leaves its trace in the terminal, the lines the
;; errorformat knows go to the quickfix list
(fn trace_to_qf [term title efm]
  (when (vim.api.nvim_buf_is_valid term)
    (Utils.set_qf title (vim.api.nvim_buf_get_lines term 0 -1 false) efm)
    (when (accumulate [any false _ e (ipairs (vim.fn.getqflist))]
            (or any (= e.valid 1)))
      (vim.cmd "botright copen"))))

(fn Utils.term_with_trace [cmd]
  (let [efm (vim.api.nvim_get_option_value :errorformat {})]
    (Utils.open_tmp_term cmd
                         (fn [term]
                           (vim.api.nvim_create_autocmd :TermClose
                                                        {:buffer term
                                                         :once true
                                                         :callback #(when (not= 0
                                                                                vim.v.event.status)
                                                                      (vim.schedule #(trace_to_qf term
                                                                                                  cmd
                                                                                                  efm)))})))))

(fn Utils.run []
  (Utils.build #(let [cmd (cmd_for :run_cmd)]
                  (if cmd
                      (Utils.term_with_trace cmd)
                      (vim.notify "no run_cmd" vim.log.levels.WARN)))))

;; Utils.test_at.<filetype> looks at the cursor and returns {:name name} to
;; run that test through test_cmd with vim.b.test_filter in front of the name
;; (like -Dtest-filter=), {:term cmd} to run cmd in a terminal at the bottom
;; instead, or nil to run test_cmd as it is
(set Utils.test_at {})

(fn Utils.test []
  (let [cmd (cmd_for :test_cmd)
        find (. Utils.test_at vim.bo.filetype)
        plan (or (and find (find)) {})
        filter (cmd_for :test_filter)]
    (if plan.term
        (do
          (vim.cmd "silent! wall")
          (Utils.term_with_trace plan.term))
        (not cmd)
        (vim.notify "no test_cmd" vim.log.levels.WARN)
        (and plan.name filter)
        ;; expandcmd would turn % and # in the name into file names
        (Utils.build nil
                     (.. cmd " " filter
                         (pick-values 1
                                      (: (vim.fn.shellescape plan.name) :gsub
                                         "[%%#]" "\\%0"))))
        (Utils.build nil cmd))))

(vim.keymap.set :n :<leader>mb #(Utils.build))
(vim.keymap.set :n :<leader>mr Utils.run)
(vim.keymap.set :n :<leader>mt Utils.test)

(fn runner [cmd]
  #(set vim.g.run_cmd cmd))

(vim.keymap.set :n :<leader>bb
                #(def_ui {:bind_nix (runner "nix-instantiate --show-trace --eval ./%")
                          :bind_zig (runner "zig build run -freference-trace=10 -j$(nproc)")
                          :bind_run (runner "make run")
                          :bind_exe (runner "./%")}))
