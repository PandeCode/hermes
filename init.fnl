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
