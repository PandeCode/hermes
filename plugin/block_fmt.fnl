(macro autocmd-ft [filetypes callback]
  `(vim.api.nvim_create_autocmd :Filetype
                                {:pattern ,filetypes :callback ,callback}))

(macro keymap-ft [mode key rhs]
  `(fn [tbl#]
     (vim.keymap.set ,mode ,key ,rhs {:buffer tbl#.buf})))

(macro wrap-format-stop-bind [filetypes start stop bind]
  `(let [fts# (if (= (type ,filetypes) :table) ,filetypes [,filetypes])]
     (autocmd-ft fts#
                 (keymap-ft :v ,bind
                            (.. "vnoremap <buffer> " ,bind " <esc>`>a" ,stop
                                "<esc>`<i" ,start :<esc>)))
     (autocmd-ft fts#
                 (keymap-ft :n ,bind
                            (.. "<esc>{o" ,start "<esc>}O" ,stop :<esc>)))))

(macro wrap-format-stop [filetypes start stop]
  `(wrap-format-stop-bind ,filetypes ,start ,stop :<space>fo))

(macro top-format-stop [filetypes top]
  `(let [fts# (if (= (type ,filetypes) :table) ,filetypes [,filetypes])]
     (autocmd-ft fts# (keymap-ft :v :<space>fo (.. "<esc>`<i" ,top :<esc>)))
     (autocmd-ft fts# (keymap-ft :n :<space>fo (.. "<esc>{o" ,top :<esc>)))))

(wrap-format-stop :lua "-- stylua: ignore start" "-- stylua: ignore end")
(wrap-format-stop :python "# fmt: off" "# fmt: on")
(wrap-format-stop [:haskell :lhaskell] "{- ORMOLU_DISABLE -}"
                  "{- ORMOLU_ENABLE -}")

(wrap-format-stop [:cpp :c] "// clang-format off" "// clang-format on")

(wrap-format-stop :zig "// zig fmt: off" "// zig fmt: on")

; // @typstyle off or /* @typstyle off */
(top-format-stop :typst "/* @typstyle off */")

(top-format-stop [:js
                  :ts
                  :tsx
                  :jsx
                  :vue
                  :json
                  :svelte
                  :javascript
                  :typescript
                  :javascriptreact
                  :typescriptreact] "// prettier-ignore")

(top-format-stop :rust "#[rustfmt::skip]")
(top-format-stop :fennel ";; fnlfmt: skip")

(wrap-format-stop-bind :python "_t=perf_counter()"
                       "print(f'_t:{perf_counter()-_t:.2f}s')" :<leader>wt)
