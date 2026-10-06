(vim.loader.enable)

;; before any include, keymaps take the leader at the time they are set
(set vim.g.mapleader " ")
(set vim.g.maplocalleader "\\")

(global Fennel nil)

(let [(ok? _fennel) (pcall (. (require :fennel) :install))]
  (when ok? (global Fennel _fennel)))

(include :fnl.utils)

(include :fnl.options)
(include :fnl.keymaps)
(include :fnl.autocmds)

(include :fnl.plugins)

(include :fnl.theme)
(include :fnl.statusline)
(include :fnl.tabline)

(include :fnl.lsp)
(include :fnl.dap)

; (vim.keymap.del :i :<c-k>)
;

(vim.api.nvim_create_user_command :Fnl
                                  (fn [opts]
                                    (vim.print (Fennel.eval opts.args)))
                                  {:nargs "+"})
