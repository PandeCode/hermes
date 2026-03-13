(local dap (require :dap))
(local dapui (require :dapui))

(dapui.setup)
((. (require :nvim-dap-virtual-text) :setup))

(fn dap.listeners.before.attach.dapui_config [] (dapui.open))
(fn dap.listeners.before.launch.dapui_config [] (dapui.open))
(fn dap.listeners.before.event_terminated.dapui_config [] (dapui.close))
(fn dap.listeners.before.event_exited.dapui_config [] (dapui.close))

(vim.keymap.set :n :<leader>db dap.toggle_breakpoint)
(vim.keymap.set :n :<leader>dc dap.continue)

(vim.keymap.set :n :<leader>do dap.step_over)
(vim.keymap.set :n :<leader>di dap.step_into)

(vim.keymap.set :n :<leader>di dap.terminate)

(vim.keymap.set :n :<leader>dr dap.repl.open)

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

(set dap.configurations.rust (mk :rust-gdb))
