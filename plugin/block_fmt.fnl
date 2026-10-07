; TODO make a textobject actions
;  fo<textobject>
;  foip format off ip
(macro autocmd-ft [filetypes callback]
  `(vim.api.nvim_create_autocmd :Filetype
                                {:pattern ,filetypes :callback ,callback}))

(macro keymap-ft [mode key rhs]
  `(fn [tbl#]
     (vim.keymap.set ,mode ,key ,rhs {:buffer tbl#.buf})))

;; puts start above the selected lines and stop below them, on lines of their
;; own with the first line's indent. set_lines rather than O and o, which
;; would continue a comment on the line next to them
(fn wrap-selection [start stop]
  (let [a (vim.fn.line :v)
        b (vim.fn.line ".")
        top (math.min a b)
        bottom (math.max a b)
        indent (: (vim.fn.getline top) :match "^%s*")]
    (vim.api.nvim_feedkeys (vim.keycode :<esc>) :nx false)
    (when stop
      (vim.api.nvim_buf_set_lines 0 bottom bottom false [(.. indent stop)]))
    (vim.api.nvim_buf_set_lines 0 (- top 1) (- top 1) false
                                [(.. indent start)])))

(macro wrap-format-stop-bind [filetypes start stop bind]
  `(let [fts# (if (= (type ,filetypes) :table) ,filetypes [,filetypes])]
     (autocmd-ft fts# (keymap-ft :x ,bind #(wrap-selection ,start ,stop)))
     (autocmd-ft fts#
                 (keymap-ft :n ,bind
                            (.. "<esc>{o" ,start "<esc>}O" ,stop :<esc>)))))

(macro wrap-format-stop [filetypes start stop]
  `(wrap-format-stop-bind ,filetypes ,start ,stop :<space>fo))

(macro top-format-stop [filetypes top]
  `(let [fts# (if (= (type ,filetypes) :table) ,filetypes [,filetypes])]
     (autocmd-ft fts# (keymap-ft :x :<space>fo #(wrap-selection ,top)))
     (autocmd-ft fts# (keymap-ft :n :<space>fo (.. "<esc>{o" ,top :<esc>)))))

(wrap-format-stop :lua "-- stylua: ignore start" "-- stylua: ignore end")
(wrap-format-stop :python "# fmt: off" "# fmt: on")
(wrap-format-stop [:haskell :lhaskell] "{- ORMOLU_DISABLE -}"
                  "{- ORMOLU_ENABLE -}")

(wrap-format-stop [:cpp :c] "// clang-format off" "// clang-format on")

(wrap-format-stop :zig "// zig fmt: off" "// zig fmt: on")

;; split so keep-sorted, which treefmt runs on every file, doesn't read
;; these strings as its own markers
(wrap-format-stop :nix (.. "# keep-" "sorted start")
                  (.. "# keep-" "sorted end"))

; // @typstyle off or /* @typstyle off */
(top-format-stop :typst "/* @typstyle off */")

(top-format-stop [:vue
                  :svelte
                  :javascript
                  :typescript
                  :javascriptreact
                  :typescriptreact] "// prettier-ignore")

(top-format-stop :rust "#[rustfmt::skip]")
(top-format-stop :fennel ";; fnlfmt: skip")

(wrap-format-stop-bind :python "_t=perf_counter()"
                       "print(f'_t:{perf_counter()-_t:.2f}s')" :<leader>wt)
