(when (= vim.g.nix_plugins nil)
  nil)

; generate from nix
; (require :nix_plugins)
; (vim.pack.add)

;; You can inject lz.n.PluginSpec fields (without the name) via the
;; `data` field.

;; @type lz.n.pack.Spec[]
(local plugins [])

;; Add the plugins, replacing the built-in `load` function
;; with lz.n's implementation.
(vim.pack.add plugins {:load (. (require :lz.n) :load)})

(macro rsetup [p t]
  `((. (require ,p) :setup) (or ,t {})))

(rsetup :oil)

(vim.keymap.set :n "-" :<cmd>Oil<CR>
                {:noremap true :desc "Open Parent Directory"})

(vim.keymap.set :n :<leader>- "<cmd>Oil .<CR>"
                {:noremap true :desc "Open nvim root directory"})

(vim.api.nvim_create_autocmd [:BufEnter :BufWrite :BufWritePost]
                             {:callback #(pcall vim.treesitter.start)})

; ((. vim.wo 0 0 :foldexpr) "v:lua.vim.treesitter.foldexpr()")
; ((. vim.wo 0 0 :foldmethod) :expr)
; ((. vim.wo 0 0 :foldmethod) :manual)

(set vim.bo.indentexpr "v:lua.require('nvim-treesitter').indentexpr()")

(local ts-ctx (require :treesitter-context))

((. ts-ctx :setup) {:enable true :multiwindow true})

(vim.keymap.set :n "[c"
                (fn []
                  ((. ts-ctx :go_to_context) vim.v.count1))
                {:silent true})

(local ts-obj (require :nvim-treesitter-textobjects))
(ts-obj.setup {:move {:set_jumps true}})

(rsetup :nvim-treesitter.config
        {:highlight {:enable true}
         :indent {:enable true}
         :incremental_selection {:enable true
                                 :keymaps {:init_selection :<c-space>
                                           :node_incremental :<c-space>
                                           :scope_incremental :<c-s>
                                           :node_decremental :<M-space>}}
         :textobjects {:select {:enable true
                                :lookahead true
                                ;; Automatically jump forward to textobj similar to targets.vim
                                :keymaps {;; You can use the capture groups defined in textobjects.scm
                                          :aa "@parameter.outer"
                                          :ia "@parameter.inner"
                                          :af "@function.outer"
                                          :if "@function.inner"
                                          :ac "@class.outer"
                                          :ic "@class.inner"}}
                       :move {:enable true
                              :set_jumps true
                              ;; whether to set jumps in the jumplist
                              :goto_next_start {"]m" "@function.outer"
                                                "]]" "@class.outer"}
                              :goto_next_end {"]M" "@function.outer"
                                              "][" "@class.outer"}
                              :goto_previous_start {"[m" "@function.outer"
                                                    "[[" "@class.outer"}
                              :goto_previous_end {"[M" "@function.outer"
                                                  "[]" "@class.outer"}}
                       :swap {:enable true
                              :swap_next {:<leader>a "@parameter.inner"}
                              :swap_previous {:<leader>A "@parameter.inner"}}}})

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
                      [:<leader>nh Snacks.notifier.show_history "Notifier Show"]])]
  (vim.keymap.set :n (. v 1) (. v 2) {:desc (. v 3)}))

(rsetup :noice {:lsp {; override markdown rendering so that **cmp** and other plugins use **Treesitter**
                      :override {:vim.lsp.util.convert_input_to_markdown_lines true
                                 :vim.lsp.util.stylize_markdown true}}
                :presets {:bottom_search true
                          ;; use a classic bottom cmdline for search
                          :command_palette true
                          ;; position the cmdline and popupmenu together
                          :long_message_to_split true
                          ;; long messages will be sent to a split
                          :inc_rename false
                          ;; enables an input dialog for inc-rename.nvim
                          :lsp_doc_border false
                          ;; add a border to hover docs and signature help
                          }})

(rsetup :mini.icons)
(rsetup :mini.cursorword)
(rsetup :mini.pairs)
(rsetup :mini.align)
(rsetup :mini.move)
(rsetup :mini.splitjoin)
(rsetup :mini.trailspace)

(vim.api.nvim_create_autocmd [:BufWritePre]
                             {:pattern "*"
                              :callback (fn []
                                          (MiniTrailspace.trim)
                                          (MiniTrailspace.trim_last_lines))})

(local capabilities
       ((. (require :blink.cmp) :get_lsp_capabilities) {:textDocument {:foldingRange {:dynamicRegistration false
                                                                                      :lineFoldingOnly true}}}))

(rsetup :blink.pairs)
(rsetup :blink.indent)
(rsetup :blink.cmp
        {:signature {:enabled true :window {:show_documentation true}}
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

; {
;   'saghen/blink.cmp',
;   -- optional: provides snippets for the snippet source
;   dependencies = { 'rafamadriz/friendly-snippets' },
;
;   -- use a release tag to download pre-built binaries
;   version = '1.*',
;   -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
;   -- build = 'cargo build --release',
;   -- If you use nix, you can build from source using latest nightly rust with:
;   -- build = 'nix run .#build-plugin',
;
;   ---@module 'blink.cmp'
;   ---@type blink.cmp.Config
;   opts = {
;     -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
;     -- 'super-tab' for mappings similar to vscode (tab to accept)
;     -- 'enter' for enter to accept
;     -- 'none' for no mappings
;     --
;     -- All presets have the following mappings:
;     -- C-space: Open menu or open docs if already open
;     -- C-n/C-p or Up/Down: Select next/previous item
;     -- C-e: Hide menu
;     -- C-k: Toggle signature help (if signature.enabled = true)
;     --
;     -- See :h blink-cmp-config-keymap for defining your own keymap
;     keymap = { preset = 'default' },
;
;     appearance = {
;       -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
;       -- Adjusts spacing to ensure icons are aligned
;       nerd_font_variant = 'mono'
;     },
;
;     -- (Default) Only show the documentation popup when manually triggered
;     completion = { documentation = { auto_show = false } },
;
;     -- Default list of enabled providers defined so that you can extend it
;     -- elsewhere in your config, without redefining it, due to `opts_extend`
;     sources = {
;       default = { 'lsp', 'path', 'snippets', 'buffer' },
;     },
;
;     -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
;     -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
;     -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
;     --
;     -- See the fuzzy documentation for more information
;     fuzzy = { implementation = "prefer_rust_with_warning" }
;   },
;   opts_extend = { "sources.default" }
; }
;
; {
;   'neovim/nvim-lspconfig',
;   dependencies = { 'saghen/blink.cmp' },
;
;   -- example using `opts` for defining servers
;   opts = {
;     servers = {
;       lua_ls = {}
;     }
;   },
;   config = function(_, opts)
;     local lspconfig = require('lspconfig')
;     for server, config in pairs(opts.servers) do
;       -- passing config.capabilities to blink.cmp merges with the capabilities in your
;       -- `opts[server].capabilities, if you've defined it
;       config.capabilities = require('blink.cmp').get_lsp_capabilities(config.capabilities)
;       lspconfig[server].setup(config)
;     end
;   end
;
;  -- example calling setup directly for each LSP
;   config = function()
;     local capabilities = require('blink.cmp').get_lsp_capabilities()
;     local lspconfig = require('lspconfig')
;
;     lspconfig['lua_ls'].setup({ capabilities = capabilities })
;   end
; }

(local null_ls (require :null-ls))

(local problems [{:pattern "​" :name "ZERO WIDTH SPACE" :replacement ""}
                 ;; ​ (U+200B)
                 {:pattern " " :name "NON-BREAKING SPACE" :replacement " "}
                 ;;   (U+00A0)
                 {:pattern "﻿" :name "BYTE ORDER MARK" :replacement ""}
                 ;; ﻿ (U+FEFF)
                 {:pattern "‍" :name "ZERO WIDTH JOINER" :replacement ""}
                 ;; ‍ (U+200D)
                 {:pattern "‎" :name "RIGHT-TO-LEFT MARK" :replacement ""}
                 ;; ‎ (U+200E)
                 {:pattern "‏" :name "LEFT-TO-RIGHT MARK" :replacement ""}
                 ;; ‏ (U+200F)
                 ])

(local no_problems {:method null_ls.methods.DIAGNOSTICS
                    :filetypes ["*"]
                    :generator {:fn (fn [params]
                                      (local diagnostics {})
                                      (each [i line (ipairs params.content)]
                                        (each [_ problem (ipairs problems)]
                                          (local [col end_col]
                                                 (line:find problem.pattern))
                                          (when (and col end_col)
                                            (table.insert diagnostics
                                                          {:row i
                                                           : col
                                                           :end_col (+ end_col
                                                                       1)
                                                           :source :no-problems
                                                           :message problem.name
                                                           :severity vim.diagnostic.severity.WARN}))))
                                      diagnostics)}})

(null_ls.setup {:sources [; Formatting
                          null_ls.builtins.formatting.fnlfmt
                          null_ls.builtins.formatting.stylua
                          null_ls.builtins.formatting.gofmt
                          null_ls.builtins.formatting.black
                          null_ls.builtins.formatting.isort
                          null_ls.builtins.formatting.alejandra
                          null_ls.builtins.formatting.nixfmt
                          null_ls.builtins.formatting.clang_format
                          null_ls.builtins.formatting.typstyle
                          null_ls.builtins.formatting.just
                          null_ls.builtins.formatting.gdformat
                          null_ls.builtins.formatting.dart_format
                          null_ls.builtins.formatting.prettierd
                          null_ls.builtins.formatting.cmake_format
                          null_ls.builtins.diagnostics.gdlint
                          (null_ls.builtins.diagnostics.glslc.with {:extra_args [:--target-env=opengl]
                                                                    ; use opengl instead of vulkan1.0
                                                                    })
                          null_ls.builtins.diagnostics.qmllint
                          null_ls.builtins.diagnostics.vale
                          null_ls.builtins.diagnostics.markdownlint
                          null_ls.builtins.diagnostics.checkmake
                          null_ls.builtins.diagnostics.cmake_lint
                          null_ls.builtins.diagnostics.statix
                          null_ls.builtins.diagnostics.deadnix
                          null_ls.builtins.diagnostics.fish
                          null_ls.builtins.hover.dictionary
                          null_ls.builtins.hover.printenv
                          null_ls.builtins.completion.spell
                          null_ls.builtins.code_actions.statix
                          null_ls.builtins.code_actions.ts_node_action]})

(null_ls.register no_problems)

(fn lsp_format_with_fallback [opts]
  (vim.lsp.buf.format {:bufnr (or opts.bufnr 0)
                       :async (or opts.async false)
                       :timeout_ms (or opts.timeout_ms 1000)}))

(vim.api.nvim_create_autocmd :BufWritePre
                             {:pattern "*"
                              :callback #(lsp_format_with_fallback {:timeout_ms 500})})

(vim.keymap.set [:n :v] :<leader>cf #(lsp_format_with_fallback))

(vim.lsp.inlay_hint.enable)

(local noice (require :noice.lsp))
(local snacks (require :snacks))

(fn n [k f d]
  (if d (vim.keymap.set :n k f {:desc (.. "LSP: " d)}) (vim.keymap.set :n k f)))

(n :gr #(snacks.picker.lsp_references) "[G]oto [R]eferences")
(n :gI #(snacks.picker.lsp_implementations) "[G]oto [I]mplementation")
;; TODO fix
(n :<leader>lds #(snacks.picker.lsp_symbols) "[D]ocument [S]ymbols")

(n :<leader>ws #(snacks.picker.lsp_workspace_symbols) "[W]orkspace [S]ymbols")

(n :<leader>ei
   #(vim.lsp.inlay_hint.enable (not (vim.lsp.inlay_hint.is_enabled)))
   "Toggle Inlay")

(n :K noice.hover "Hover Documentation")
;; TODO fix
;; nmap("<C-k>", noice.signature, "Signature Documentation")
;; TODO fix
(n :<leader>ltd vim.lsp.buf.type_definition "Type [D]efinition")
(n :<space>cl vim.lsp.codelens.run "[C]ode [L]ens")
(n :<F2> vim.lsp.buf.rename "[R]e[n]ame")
(n :<leader>ca vim.lsp.buf.code_action "[C]ode [A]ction")

(n :gd vim.lsp.buf.definition "[G]oto [D]efinition")
(n :gD vim.lsp.buf.declaration "[G]oto [D]eclaration")

(each [_ k (ipairs [:emmylua_ls
                    :fennel_ls
                    :nixd
                    :pyright
                    :neocmake
                    :zls
                    :racket_langserver
                    :gopls])]
  (vim.lsp.enable k))

(vim.lsp.config :nixd
                {:settings {:nixd {:nixpkgs {:expr (or vim.g.nix_nixd_nixpkgs
                                                       "import <nixpkgs> {}")}
                                   :options {:nixos {:expr vim.g.nix_nixd_nixos_options}
                                             :home-manager {:expr vim.g.nix_nixd_home_manager_options}}
                                   :formatting {:command [:nixfmt]}
                                   :diagnostic {:suppress [:sema-escaping-with]}}}})
