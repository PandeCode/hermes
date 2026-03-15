(local capabilities
       ((. (require :blink.cmp) :get_lsp_capabilities) {:textDocument {:foldingRange {:dynamicRegistration false
                                                                                      :lineFoldingOnly true}}}))

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
