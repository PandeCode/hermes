(vim.cmd "packadd nvim.undotree")
(vim.cmd "packadd nvim.difftool")

(macro rsetup [p t]
  `((. (require ,p) :setup) (or ,t {})))

(rsetup :oil)

(vim.keymap.set :n "-" :<cmd>Oil<CR>
                {:noremap true :desc "Open Parent Directory"})

(vim.keymap.set :n :<leader>- "<cmd>Oil .<CR>"
                {:noremap true :desc "Open nvim root directory"})

(vim.api.nvim_create_autocmd :FileType
                             {:group (vim.api.nvim_create_augroup :treesitter_start
                                                                  {})
                              :callback (fn [args]
                                          (when (pcall vim.treesitter.start
                                                       args.buf)
                                            (set (. vim.bo args.buf :indentexpr)
                                                 "v:lua.require'nvim-treesitter'.indentexpr()")))})

; ((. vim.wo 0 0 :foldexpr) "v:lua.vim.treesitter.foldexpr()")
; ((. vim.wo 0 0 :foldmethod) :expr)
; ((. vim.wo 0 0 :foldmethod) :manual)

(local ts-ctx (require :treesitter-context))

((. ts-ctx :setup) {:enable true :multiwindow true})

;; in a diff [c keeps its builtin job, the previous change
(vim.keymap.set :n "[c"
                (fn []
                  (if vim.wo.diff
                      (vim.cmd (.. "normal! " vim.v.count1 "[c"))
                      ((. ts-ctx :go_to_context) vim.v.count1)))
                {:silent true})

(local ts-obj (require :nvim-treesitter-textobjects))
(ts-obj.setup {:select {:lookahead true} :move {:set_jumps true}})

(local ts-select (require :nvim-treesitter-textobjects.select))
(local ts-move (require :nvim-treesitter-textobjects.move))
(local ts-swap (require :nvim-treesitter-textobjects.swap))

(each [key capture (pairs {:aa "@parameter.outer"
                           :ia "@parameter.inner"
                           :af "@function.outer"
                           :if "@function.inner"
                           :ac "@class.outer"
                           :ic "@class.inner"})]
  (vim.keymap.set [:x :o] key #(ts-select.select_textobject capture :textobjects)))

(each [key [move capture] (pairs {"]m" [:goto_next_start "@function.outer"]
                                  "]]" [:goto_next_start "@class.outer"]
                                  "]M" [:goto_next_end "@function.outer"]
                                  "][" [:goto_next_end "@class.outer"]
                                  "[m" [:goto_previous_start "@function.outer"]
                                  "[[" [:goto_previous_start "@class.outer"]
                                  "[M" [:goto_previous_end "@function.outer"]
                                  "[]" [:goto_previous_end "@class.outer"]})]
  (vim.keymap.set [:n :x :o] key #((. ts-move move) capture :textobjects)))

(vim.keymap.set :n :<leader>a #(ts-swap.swap_next "@parameter.inner"))
(vim.keymap.set :n :<leader>A #(ts-swap.swap_previous "@parameter.inner"))

;; an and in are the built-in node selection in visual mode
(vim.keymap.set :n :<c-space> :van {:remap true})
(vim.keymap.set :x :<c-space> :an {:remap true})
(vim.keymap.set :x :<M-space> :in {:remap true})

;; fnlfmt: skip
((. (require :snacks) :setup) {:bigfile {:enabled true}
                               :dashboard {:enabled false}
                               :explorer {:enabled true}
                               :indent {:enabled true}
                               :input {:enabled true}
                               :picker {:enabled true}
                               :notifier {:enabled true}
                               :quickfile {:enabled true}
                               :scope {:enabled true}
                               :scroll {:enabled true}
                               :statuscolumn {:enabled true}
                               :words {:enabled true}})

(fn sk [c]
  (fn [] ((. Snacks.picker c))))

;; fnlfmt: skip
(each [_ v (ipairs [[:<leader>ff (sk :files) "Find Files"]
                    [:<leader>fr (sk :grep) :Grep]
                    [:<leader>fm (sk :marks) :Marks]
                    [:<leader>fn (sk :man) :Man]
                    [:<leader><space> (sk :smart) "Smart Find Files"]
                    [:<leader>fb (sk :buffers) :Buffers]
                    [:<leader>ch (sk :cliphist) :cliphist]
                    [:<leader>fll (sk :loclist) :loclist]
                    [:<leader>fq (sk :qflist) :qflist]
                    [:<leader>fld (sk :lsp_declarations) :lsp_declarations]
                    [:<leader>fle (sk :lsp_definitions) :lsp_definitions]
                    [:<leader>fli (sk :lsp_implementations) :lsp_implementations]
                    [:<leader>flr (sk :lsp_references) :lsp_references]
                    [:<leader>fls (sk :lsp_symbols) :lsp_symbols]
                    [:<leader>nh Snacks.notifier.hide "Notifier Hide"]
                    [:<leader>ns Snacks.notifier.show_history "Notifier Show"]])]
  (vim.keymap.set :n (. v 1) (. v 2) {:desc (. v 3)}))

(rsetup :noice {:lsp {; override markdown rendering so that **cmp** and other plugins use **Treesitter**
                      :override {:vim.lsp.util.convert_input_to_markdown_lines true
                                 :vim.lsp.util.stylize_markdown true}}
                :presets {:bottom_search false
                          ;; use a classic bottom cmdline for search
                          :command_palette true
                          ;; position the cmdline and popupmenu together
                          :long_message_to_split true
                          ;; long messages will be sent to a split
                          :inc_rename false
                          ;; enables an input dialog for inc-rename.nvim
                          :lsp_doc_border true}})

;; add a border to hover docs and signature help

(rsetup :mini.icons)
(rsetup :mini.cursorword)
(rsetup :mini.pairs)
(rsetup :mini.align)
(rsetup :mini.move)
(rsetup :mini.splitjoin)
(rsetup :mini.trailspace)

(local miniclue (require :mini.clue))
(rsetup :mini.clue {:triggers [{:mode [:n :x] :keys :<leader>}
                               {:mode [:n :x] :keys :g}
                               {:mode [:n :x] :keys :z}
                               {:mode [:n :x] :keys :<c-w>}
                               {:mode [:n :x] :keys "'"}
                               {:mode [:n :x] :keys "`"}
                               {:mode [:n :x] :keys "\""}]
                    :clues [(miniclue.gen_clues.square_brackets)
                            (miniclue.gen_clues.builtin_completion)
                            (miniclue.gen_clues.marks)
                            (miniclue.gen_clues.registers)
                            (miniclue.gen_clues.windows)
                            (miniclue.gen_clues.z)
                            (miniclue.gen_clues.g)]})

(local hipatterns (require :mini.hipatterns))
(rsetup :mini.hipatterns
        {:highlighters {:fixme {:pattern "%f[%w]()FIXME()%f[%W]"
                                :group :MiniHipatternsFixme}
                        :error {:pattern "%f[%w]()ERROR()%f[%W]"
                                :group :MiniHipatternsFixme}
                        :err {:pattern "%f[%w]()ERR()%f[%W]"
                              :group :MiniHipatternsFixme}
                        :bug {:pattern "%f[%w]()BUG()%f[%W]"
                              :group :MiniHipatternsFixme}
                        :hack {:pattern "%f[%w]()HACK()%f[%W]"
                               :group :MiniHipatternsHack}
                        :warn {:pattern "%f[%w]()WARN()%f[%W]"
                               :group :MiniHipatternsHack}
                        :todo {:pattern "%f[%w]()TODO()%f[%W]"
                               :group :MiniHipatternsTodo}
                        :note {:pattern "%f[%w]()NOTE()%f[%W]"
                               :group :MiniHipatternsNote}
                        :info {:pattern "%f[%w]()INFO()%f[%W]"
                               :group :MiniHipatternsNote}
                        :base00 {:pattern :base00 :group :GP_base00}
                        :base01 {:pattern :base01 :group :GP_base01}
                        :base02 {:pattern :base02 :group :GP_base02}
                        :base03 {:pattern :base03 :group :GP_base03}
                        :base04 {:pattern :base04 :group :GP_base04}
                        :base05 {:pattern :base05 :group :GP_base05}
                        :base06 {:pattern :base06 :group :GP_base06}
                        :base07 {:pattern :base07 :group :GP_base07}
                        :base08 {:pattern :base08 :group :GP_base08}
                        :base09 {:pattern :base09 :group :GP_base09}
                        :base0A {:pattern :base0A :group :GP_base0A}
                        :base0B {:pattern :base0B :group :GP_base0B}
                        :base0C {:pattern :base0C :group :GP_base0C}
                        :base0D {:pattern :base0D :group :GP_base0D}
                        :base0E {:pattern :base0E :group :GP_base0E}
                        :base0F {:pattern :base0F :group :GP_base0F}
                        :hex_color (hipatterns.gen_highlighter.hex_color)
                        :hex_num {;; 0xffffff
                                  :pattern "0x%x%x%x%x%x%x%f[%X]"
                                  :group (fn [_ _ data]
                                           (MiniHipatterns.compute_hex_color_group (data.full_match:gsub :0x
                                                                                                         "#")
                                                                                   :bg))
                                  :extmark_opts {:priority 200}}}})

(local mini_s (require :mini.surround))

;; fnlfmt: skip
(local ts_input  mini_s.gen_spec.input.treesitter)

(mini_s.setup {:mappings {:add :ys
                          :delete :ds
                          :find ""
                          :find_left ""
                          :highlight ""
                          :replace :cs
                          :update_n_lines ""
                          ;; Add this only if you don't want to use extended mappings
                          :suffix_last ""
                          :suffix_next ""}
               :search_method :cover_or_next
               :custom_surroundings {:f {:input (ts_input {:outer "@call.outer"
                                                           :inner "@call.inner"})}
                                     :b {:input (ts_input {:outer "@block.outer"
                                                           :inner "@block.inner"})}
                                     ;; Make `)` insert parts with spaces. `input` pattern stays the same.
                                     ")" {:output {:left "( " :right " )"}}
                                     ;; Use function to compute surrounding info
                                     :* {:input #(do
                                                   (local n_star
                                                          (MiniSurround.user_input "Number of * to find"))
                                                   (local many_star
                                                          (string.rep "%*"
                                                                      (or (tonumber n_star)
                                                                          1)))
                                                   [(.. many_star "().-()"
                                                        many_star)])
                                         :output #(do
                                                    (local n_star
                                                           (MiniSurround.user_input "Number of * to output"))
                                                    (local many_star
                                                           (string.rep "%*"
                                                                       (or (tonumber n_star)
                                                                           1)))
                                                    {:left many_star
                                                     :right many_star})}}})

;; Remap adding surrounding to Visual mode selection
(vim.keymap.del :x :ys)
(vim.keymap.set :x :S ":<C-u>lua MiniSurround.add('visual')<CR>" {:silent true})

;; Make special mapping for "add surrounding for line"
(vim.keymap.set :n :yss :ys_ {:remap true})

(vim.api.nvim_create_autocmd [:BufWritePre]
                             {:pattern "*"
                              :callback (fn []
                                          (MiniTrailspace.trim)
                                          (MiniTrailspace.trim_last_lines))})

;; the directory init.lua was loaded from: the nix store copy, or a checkout
(local hermes-dir
       (vim.fs.dirname (: (. (debug.getinfo 1 :S) :source) :sub 2)))

(rsetup :blink.indent)
(rsetup :blink.cmp
        {:fuzzy {:implementation :prefer_rust}
         :keymap {:<C-k> {}}
         :signature {:enabled true :window {:show_documentation true}}
         :sources {:providers {:snippets {:opts {:search_paths [(.. hermes-dir
                                                                       :/snippets)]}}}}
         :completion {:menu {:draw {:treesitter [:lsp]
                                    :columns [[:kind_icon]
                                              {1 :label
                                               2 :label_description
                                               :gap 1}
                                              [:kind]]
                                    :components {:kind_icon {:text (fn [ctx]
                                                                     (local (kind_icon _
                                                                                       _)
                                                                            (MiniIcons.get :lsp
                                                                                           ctx.kind))
                                                                     kind_icon)
                                                             :highlight (fn [ctx]
                                                                          (local (_ hl
                                                                                    _)
                                                                                 (MiniIcons.get :lsp
                                                                                                ctx.kind))
                                                                          hl)}
                                                 :kind {:highlight (fn [ctx]
                                                                     (local (_ hl
                                                                               _)
                                                                            (MiniIcons.get :lsp
                                                                                           ctx.kind))
                                                                     hl)}}}}
                      :documentation {:auto_show true}}})

;; parinfer-rust only has a global switch, so each buffer keeps its own
;; b:parinfer_on and BufEnter applies it. the callbacks return nil: an
;; autocmd callback that returns a truthy value deletes the autocmd
(local parinfer-filetypes [:racket :lisp :wat :wasm :fennel])

(fn parinfer-apply []
  (pcall vim.cmd (if vim.b.parinfer_on :ParinferOn :ParinferOff))
  (vim.cmd.redrawstatus)
  nil)

(fn parinfer-set [on]
  (set vim.b.parinfer_on on)
  (parinfer-apply))

(fn parinfer-on [] (parinfer-set true))
(fn parinfer-off [] (parinfer-set false))
(fn parinfer-toggle [] (parinfer-set (not vim.b.parinfer_on)))

(vim.keymap.set :n :<leader>po parinfer-on {:desc :parinfer-on})
(vim.keymap.set :n :<leader>pf parinfer-off {:desc :parinfer-off})
(vim.keymap.set :n :<leader>pt parinfer-toggle {:desc :parinfer-toggle})

(vim.api.nvim_create_autocmd :FileType
                             {:callback #(parinfer-set (vim.tbl_contains parinfer-filetypes
                                                                         vim.bo.filetype))})

(vim.api.nvim_create_autocmd :BufEnter {:callback parinfer-apply})

(local lz (require :lz.n))

;; the opt plugins from nix/editor.nix. DeferredUIEnter is right after the
;; first screen is drawn, ft loads replay the FileType event for the buffer
;; fnlfmt: skip
(lz.load [{1 :zig.vim :ft :zig}
          {1 :vlime :ft :lisp}
          ;; its debuggables need nvim-dap on the runtimepath
          {1 :rustaceanvim :ft :rust :before #(lz.trigger_load :nvim-dap)}
          {1 :vim-sleuth :event [:BufReadPost :BufNewFile]}
          {1 :vim-wakatime :event :DeferredUIEnter}
          {1 :vim-visual-multi :event :DeferredUIEnter}
          {1 :vim-wordmotion :event :DeferredUIEnter}
          {1 :refactoring.nvim :cmd :Refactor}
          {1 :neogen
           :cmd :Neogen
           :keys [{1 :<leader>nf 2 #((. (require :neogen) :generate))}]
           :after #(rsetup :neogen)}])
