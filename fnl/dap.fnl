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

;; nvim-dap and its frontends are opt plugins, lz.n loads them on the first
;; debug key or command
(fn setup []
  (local dap (require :dap))

  ((. (require :nvim-dap-virtual-text) :setup))

  ; (local frontend (require :dapui))
  (local frontend (require :dap-view))
  (frontend.setup {:winbar {:controls {:enabled true}}})

  (fn dap.listeners.before.attach.dapui_config [] (frontend.open))
  (fn dap.listeners.before.launch.dapui_config [] (frontend.open))
  (fn dap.listeners.before.event_terminated.dapui_config [] (frontend.close))
  (fn dap.listeners.before.event_exited.dapui_config [] (frontend.close))

  ;; only the web and full profiles ship the firefox adapter
  (let [firefox-debug (os.getenv :VSCODE_FIREFOX_DEBUG)]
    (when firefox-debug
      (set dap.adapters.firefox
           {:type :executable
            :command :node
            :args [(.. firefox-debug :/dist/adapter.bundle.js)]})))

  (set dap.configurations.typescript
       [{:name "Debug Firefox"
         :type :firefox
         :request :launch
         :reAttach true
         :url "http://localhost:8080"
         :webRoot "${workspaceFolder}"
         :firefoxExecutable (or (os.getenv :BROWSER) :firefox)}
        {:name "Attach Firefox"
         :type :firefox
         :request :attach
         :reAttach true
         :url "http://localhost:8080"
         :webRoot "${workspaceFolder}"
         :firefoxExecutable (or (os.getenv :BROWSER) :firefox)}])

  (set dap.configurations.javascript dap.configurations.typescript)
  (set dap.configurations.javascriptreact dap.configurations.typescript)
  (set dap.configurations.typescriptreact dap.configurations.typescript)

  (set dap.adapters.gdb {:type :executable
                         :command :gdb
                         :args [:--interpreter=dap
                                :--eval-command
                                "set print pretty on"]})

  (set dap.adapters.rust-gdb
       {:type :executable
        :command :rust-gdb
        :args [:--interpreter=dap :--eval-command "set print pretty on"]})

  (set dap.configurations.c (mk :gdb))
  (set dap.configurations.cpp dap.configurations.c)
  (set dap.configurations.zig dap.configurations.c)

  (set dap.configurations.rust (mk :rust-gdb))

  ;; K is dap-view hover while a session runs; every K it replaced, global
  ;; and buffer-local, comes back with mapset when the session ends. sessions
  ;; counts open ones, a child session sends its own initialized and
  ;; terminated, so only the first and the last swap K
  (var keymap_restore [])
  (var sessions 0)

  (fn dap.listeners.after.event_initialized.me []
    (set sessions (+ sessions 1))
    (when (= sessions 1)
      (set keymap_restore [])
      (each [_ keymap (ipairs (vim.api.nvim_get_keymap :n))]
        (when (= keymap.lhs :K)
          (table.insert keymap_restore keymap)))
      (each [_ buf (ipairs (vim.api.nvim_list_bufs))]
        (each [_ keymap (ipairs (vim.api.nvim_buf_get_keymap buf :n))]
          (when (= keymap.lhs :K)
            (table.insert keymap_restore keymap)
            (vim.api.nvim_buf_del_keymap buf :n :K))))
      (vim.keymap.set :n :K #(frontend.hover) {:silent true})))

  (fn dap.listeners.after.event_terminated.me []
    (when (> sessions 0)
      (set sessions (- sessions 1))
      (when (= sessions 0)
        (vim.keymap.del :n :K)
        (each [_ keymap (ipairs keymap_restore)]
          (if (= keymap.buffer 0)
              (vim.fn.mapset keymap)
              ;; mapset puts buffer maps on the current buffer
              (when (vim.api.nvim_buf_is_valid keymap.buffer)
                (vim.api.nvim_buf_call keymap.buffer
                                       #(vim.fn.mapset keymap)))))
        (set keymap_restore []))))

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
  (vim.keymap.set :n :<leader>det
                  (. (require :nvim-dap-virtual-text) :toggle)
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
    (vim.fn.sign_define name sign)))

;; fnlfmt: skip
((. (require :lz.n) :load)
 {1 :nvim-dap
  :keys [:<leader>db :<leader>dc :<leader>do :<leader>di :<leader>dt :<leader>dr
         :<M-c> :<M-o> :<M-i> :<M-t> :<M-r>
         :<leader>dui :<leader>dux :<leader>det]
  :cmd [:DapContinue :DapNew :DapToggleBreakpoint]
  :before #(each [_ p (ipairs [:nvim-dap-view :nvim-dap-virtual-text])]
             (vim.cmd.packadd p))
  :after setup})
