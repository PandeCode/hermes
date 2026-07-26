(vim.loader.enable)
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
                                    (Fennel.eval (table.concat opts.fargs)
                                                 {:nargs 1})))

(vim.cmd "cnoreabbrev fnl Fnl")
