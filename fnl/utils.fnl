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
(fn open_tmp_term [cmd]
  (vim.cmd (.. "botright split | terminal " cmd))
  (local bufnr (vim.api.nvim_win_get_buf 0))
  (vim.api.nvim_set_option_value :buflisted false {:buf bufnr})
  (vim.api.nvim_set_option_value :bufhidden :wipe {:buf bufnr})
  (local h (math.floor (/ vim.o.lines 4)))
  (vim.cmd (.. "resize " h))
  (vim.cmd "wincmd p"))

(set Utils {})

(fn Utils.bind_term [bind cmd]
  (vim.keymap.set :n bind #(Utils.open_tmp_term cmd)))

(fn Utils.bind_job [bind cmd]
  (vim.keymap.set :n bind #(vim.fn.jobstart [:sh :-c cmd])))

(fn Utils.bind_tmux [bind cmd]
  (Utils.bind_job bind
                  (.. "tmux split-window -l 10 '" cmd
                      " && exit 0 || tmux last-pane & cat'; tmux copy-mode; tmux last-pane")))
