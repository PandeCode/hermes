(local dap (require :dap))

((. (require :nvim-dap-virtual-text) :setup))

; (local frontend (require :dapui))
(local frontend (require :dap-view))
(frontend.setup {:winbar {:controls {:enabled true}}})

(fn dap.listeners.before.attach.dapui_config [] (frontend.open))
(fn dap.listeners.before.launch.dapui_config [] (frontend.open))
(fn dap.listeners.before.event_terminated.dapui_config [] (frontend.close))
(fn dap.listeners.before.event_exited.dapui_config [] (frontend.close))

(fn dap.listeners.before.event_terminated.my-plugin [session body]
  (vim.notify (.. "Session terminated" (vim.inspect session) (vim.inspect body))))

(set dap.adapters.gdb {:type :executable
                       :command :gdb
                       :args [:--interpreter=dap
                              :--eval-command
                              "set print pretty on"]})

(set dap.adapters.rust-gdb
     {:type :executable
      :command :rust-gdb
      :args [:--interpreter=dap :--eval-command "set print pretty on"]})

(macro mk [n]
  `(let [pick# #(vim.fn.input "Path to executable: " (.. (vim.fn.getcwd) "/")
                              :file)]
     [{:name :Launch
       :type ,n
       :request :launch
       :program pick#
       :args {}
       :cwd "${workspaceFolder}"
       :stopAtBeginningOfMainSubprogram false}
      {:name "Select and attach to process"
       :type ,n
       :request :attach
       :program pick#
       :pid #(do
               (local name# (vim.fn.input "Executable name (filter): "))
               ((. (require :dap.utils) :pick_process) {:filter name#}))
       :cwd "${workspaceFolder}"}
      {:name "Attach to gdbserver :1234"
       :type ,n
       :request :attach
       :target "localhost:1234"
       :program pick#
       :cwd "${workspaceFolder}"}]))

(set dap.configurations.c (mk :gdb))
(set dap.configurations.cpp dap.configurations.c)
(set dap.configurations.zig dap.configurations.c)

(set dap.configurations.rust (mk :rust-gdb))

(local keymap_restore {})

(lua "
dap.listeners.after['event_initialized']['me'] = function()
  for _, buf in pairs(vim.api.nvim_list_bufs()) do
    local keymaps = vim.api.nvim_buf_get_keymap(buf, 'n')
    for _, keymap in pairs(keymaps) do
      if keymap.lhs == 'K' then
        table.insert(keymap_restore, keymap)
        vim.api.nvim_buf_del_keymap(buf, 'n', 'K')
      end
    end
  end
  vim.api.nvim_set_keymap(
                      'n', 'K', '<Cmd>lua require(\"dap-view\").hover()', { silent = true})
end

dap.listeners.after['event_terminated']['me'] = function()
  for _, keymap in pairs(keymap_restore) do
    if keymap.rhs then
      vim.api.nvim_buf_set_keymap(
                              keymap.buffer,
                              keymap.mode,
                              keymap.lhs,
                              keymap.rhs,
                              { silent = keymap.silent == 1})

    elseif keymap.callback then
      vim.keymap.set(
                     keymap.mode,
                     keymap.lhs,
                     keymap.callback,
                     { buffer = keymap.buffer, silent = keymap.silent == 1})

    end
  end
  keymap_restore = {}
end
")

(vim.keymap.set :n :<leader>db dap.toggle_breakpoint
                {:desc "Dap toggle_breakpoint"})

(vim.keymap.set :n :<leader>dc dap.continue {:desc "Dap continue"})
(vim.keymap.set :n :<leader>do dap.step_over {:desc "Dap step_over"})
(vim.keymap.set :n :<leader>di dap.step_into {:desc "Dap step_into"})
(vim.keymap.set :n :<leader>dt dap.terminate {:desc "Dap terminate"})
(vim.keymap.set :n :<leader>dr dap.repl.open {:desc "Dap repl.open"})

(vim.keymap.set :n :<M-c> dap.continue {:desc "Dap continue."})
(vim.keymap.set :n :<M-o> dap.step_over {:desc "Dap step_over."})
(vim.keymap.set :n :<M-i> dap.step_into {:desc "Dap step_into."})
(vim.keymap.set :n :<M-t> dap.terminate {:desc "Dap terminate."})
(vim.keymap.set :n :<M-r> dap.repl.open {:desc "Dap repl.open."})

(vim.keymap.set :n :<leader>dui frontend.open {:desc "Dap ui open"})
(vim.keymap.set :n :<leader>dux frontend.close {:desc "Dap ui close"})
(vim.keymap.set :n :<leader>det frontend.virtual_text_toggle
                {:desc "Dap virt text toggle"})

(each [name sign (pairs {:DapBreakpoint {:text ""
                                         :texthl :DiagnosticError
                                         :linehl ""
                                         :numhl ""}
                         :DapBreakpointCondition {:text ""
                                                  :texthl :DiagnosticWarn
                                                  :linehl ""
                                                  :numhl ""}
                         :DapBreakpointRejected {:text ""
                                                 :texthl :DiagnosticError
                                                 :linehl ""
                                                 :numhl ""}
                         :DapLogPoint {:text "󰆈"
                                       :texthl :DiagnosticInfo
                                       :linehl ""
                                       :numhl ""}
                         :DapStopped {:text ""
                                      :texthl :DiagnosticWarn
                                      :linehl :CursorLine
                                      :numhl :DiagnosticWarn}})]
  (vim.fn.sign_define name sign))
