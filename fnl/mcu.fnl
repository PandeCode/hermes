;; cortex-m boards behind a gdb server, pyocd by default. nothing happens until
;; a project's .nvim.lua calls Mcu.setup:
;;
;;   Mcu.setup({ elf = "blink/build/Debug/blink.elf", build = "just build",
;;               flash = "just flash", serial = "just serial" })
;;
;; <leader>mb builds, <leader>mr flashes, <leader>dm builds, loads and runs to
;; main under gdb's own dap, the dap-view winbar gets Peripherals (pyocd reads
;; the svd from the pack) and RTT. gdb has to know arm, nixpkgs' gdb does
(global Mcu {})

;; without --persist pyocd quits when gdb disconnects, which frees the probe
;; for `just flash`
(local defaults {:server "pyocd gdbserver"
                 ;; pyocd prints this once gdb can connect
                 :ready "listening on port"
                 :port 3333
                 :gdb :gdb
                 :reset ["monitor reset halt"]
                 :run_to :main
                 :rtt {:port 19021 :channel 0}
                 :filetypes [:c :cpp :asm :zig]})

(var config nil)
(var server nil)
;; outlives the server, so a crash can still be read
(var log nil)

(fn notify [msg level]
  (vim.notify (.. "mcu: " msg) level))

(fn elf []
  (vim.fs.joinpath config.root (if (= (type config.elf) :function)
                                   (config.elf)
                                   config.elf)))

;; gdb server

(fn server_output [_ data]
  (vim.api.nvim_buf_set_lines log -1 -1 false data)
  (when (and server (not server.ready))
    ;; a line can come split over two calls
    (set server.tail (.. server.tail (table.concat data "\n")))
    (when (string.find server.tail config.ready 1 true)
      (set server.ready true)
      (each [_ f (ipairs server.waiting)]
        (f)))
    (set server.tail (or (server.tail:match "[^\n]*$") ""))))

(fn server_exit [_ code]
  (when (and server (not server.stopping) (not= code 0))
    (notify (.. "gdb server exited with " code ", see :McuServer")
            vim.log.levels.ERROR))
  (set server nil))

(fn server_start [on_ready]
  (when (not (and log (vim.api.nvim_buf_is_valid log)))
    (set log (vim.api.nvim_create_buf false true))
    (vim.api.nvim_buf_set_name log "mcu://gdbserver"))
  (if (not server)
      (do
        (set server {:ready false :tail "" :waiting [on_ready]})
        (set server.job
             (vim.fn.jobstart config.server
                              {:cwd config.root
                               :on_stdout server_output
                               :on_stderr server_output
                               :on_exit server_exit})))
      server.ready
      (on_ready)
      (table.insert server.waiting on_ready)))

(fn server_toggle [opts]
  (if (and server opts.bang)
      (do
        (set server.stopping true)
        (vim.fn.jobstop server.job))
      (do
        (server_start #(notify "gdb server up"))
        (vim.cmd (.. "botright sbuffer " log)))))

;; dap

(fn repl [session cmd]
  (let [(err res) (session:request :evaluate {:expression cmd :context :repl})
        dap-repl (require :dap.repl)]
    (dap-repl.append (.. "> " cmd))
    (if err
        (do
          (dap-repl.append err.message)
          nil)
        (do
          (when (not= res.result "")
            (dap-repl.append (vim.trim res.result)))
          res.result))))

;; gdb's attach stops wherever the core was. a flash run loads the elf over the
;; gdb server, resets and runs to main like `just debug` does
(fn on_attach [session]
  (when session.config.mcu_load
    (when (repl session :load)
      (each [_ cmd (ipairs config.reset)]
        (repl session cmd))
      ;; the reset moved the pc behind gdb's back
      (repl session "maintenance flush register-cache")
      (when config.run_to
        (repl session (.. "tbreak " config.run_to))
        (session:request :continue {:threadId 1})))))

(fn mcu_session? [session]
  (and session (= session.config.type :mcu)))

(fn configurations []
  [{:name "Flash and debug"
    :type :mcu
    :request :attach
    :target (.. "localhost:" config.port)
    :program elf
    :mcu_load true}
   {:name "Attach to the running board"
    :type :mcu
    :request :attach
    :target (.. "localhost:" config.port)
    :program elf
    :mcu_load false}])

;; peripherals view: pyocd's `show peripherals` and `rr` through gdb's monitor,
;; only while the core is halted. <CR> opens a peripheral into its registers
;; and a register into its fields, every stop reads the open ones again

(local periph {:buf nil :list nil :open {} :text {}})

(fn monitor [session cmd]
  (let [(err res) (session:request :evaluate
                                   {:expression (.. "monitor " cmd)
                                    :context :repl})]
    (if err (.. "error: " err.message) res.result)))

(fn periph_lines []
  (let [lines []
        rows []]
    (fn add [text row]
      (table.insert lines text)
      (table.insert rows row))

    (fn sign [key]
      (if (. periph.open key) "- " "+ "))

    (add (.. (sign :fault) :Faults) {:key :fault})
    (when (. periph.open :fault)
      (each [_ l (ipairs (vim.split (or (. periph.text :fault) "") "\n"
                                    {:trimempty true}))]
        (add (.. "  " l) {})))
    (each [_ p (ipairs (or periph.list []))]
      (add (.. (sign p.name) p.name) {:key p.name})
      (when (. periph.open p.name)
        (each [_ l (ipairs (vim.split (or (. periph.text p.name) "") "\n"
                                      {:trimempty true}))]
          ;; GPIOA.MODER @ 42020000 = abffffff
          (let [reg (l:match "^%S+%.(%S+) @")
                key (and reg (.. p.name "." reg))]
            (add (.. "    " l) (if key {: key} {}))
            (when (and key (. periph.open key))
              (each [_ f (ipairs (vim.split (or (. periph.text key) "") "\n"
                                            {:trimempty true}))]
                (when (f:match "^%s")
                  (add (.. "      " (vim.trim f)) {}))))))))
    (values lines rows)))

(fn periph_render []
  (when (and periph.buf (vim.api.nvim_buf_is_valid periph.buf))
    (let [(lines rows) (periph_lines)]
      (set periph.rows rows)
      (tset (. vim.bo periph.buf) :modifiable true)
      (vim.api.nvim_buf_set_lines periph.buf 0 -1 false lines)
      (tset (. vim.bo periph.buf) :modifiable false))))

(fn periph_read [session key]
  (tset periph.text key
        (monitor session (if (= key :fault) "show fault"
                             (key:find "." 1 true) (.. "rr -p -f " key)
                             (.. "rr -p " key)))))

(fn periph_list [session]
  (let [out (monitor session "show peripherals")]
    ;; 0x42020000: GPIOA
    (set periph.list (icollect [line (out:gmatch "[^\n]+")]
                       (let [name (line:match "^%s*0x%x+:%s+(%S+)")]
                         (when name {: name}))))))

(fn periph_refresh []
  (let [session ((. (require :dap) :session))]
    (when (and (mcu_session? session) session.stopped_thread_id)
      ((coroutine.wrap #(do
                          (when (not periph.list) (periph_list session))
                          (each [key _ (pairs periph.open)]
                            (periph_read session key))
                          (periph_render)))))))

(fn periph_toggle []
  (let [row (. periph.rows (vim.fn.line "."))
        key (and row row.key)]
    (when key
      (tset periph.open key (if (. periph.open key) nil true))
      (if (. periph.open key) (periph_refresh) (periph_render)))))

(fn periph_buffer []
  (let [buf (vim.api.nvim_create_buf false true)]
    (set periph.buf buf)
    (vim.api.nvim_buf_set_name buf "mcu://peripherals")
    (tset (. vim.bo buf) :filetype :mcu-peripherals)
    (vim.keymap.set :n :<CR> periph_toggle {:buffer buf :desc "Open or close"})
    (vim.keymap.set :n :r periph_refresh {:buffer buf :desc "Read again"})
    (periph_render)
    buf))

;; rtt view: pyocd's rtt server through gdb's monitor, the firmware needs
;; SEGGER RTT linked in. the control block only has its id once the firmware
;; ran SEGGER_RTT_Init, so every stop tries again until it is found

(local rtt {:buf nil :chan nil :tcp nil :up false})

(fn rtt_write [text]
  (when rtt.chan
    (vim.api.nvim_chan_send rtt.chan (pick-values 1 (text:gsub "\r?\n" "\r\n")))))

(fn rtt_connect []
  (let [tcp (vim.uv.new_tcp)]
    (set rtt.tcp tcp)
    (tcp:connect :127.0.0.1 config.rtt.port
                 (fn [err]
                   (if err
                       (vim.schedule #(rtt_write (.. "rtt: " err "\n")))
                       (tcp:read_start (fn [_ data]
                                         (when data
                                           (vim.schedule #(rtt_write data))))))))))

(fn rtt_start [session]
  (set rtt.up :trying)
  (let [(err addr) (session:request :evaluate
                                    {:expression "(unsigned long)&_SEGGER_RTT"
                                     :context :watch})
        (_ size) (when addr
                   (session:request :evaluate
                                    {:expression "sizeof(_SEGGER_RTT)"
                                     :context :watch}))]
    (if (and err (err.message:find "No symbol" 1 true))
        (do
          (rtt_write "no _SEGGER_RTT in the elf\n")
          (set rtt.up :none))
        ;; the core ran on before gdb answered, the next stop tries again
        (not size)
        (set rtt.up false)
        (let [out (.. (monitor session
                               (string.format "rtt setup %s %s SEGGER RTT"
                                              addr.result size.result))
                      (monitor session "rtt start"))
              found (out:find "Found RTT control block" 1 true)]
          (when found
            (monitor session
                     (string.format "rtt server start %d %d" config.rtt.port
                                    config.rtt.channel))
            (rtt_connect))
          (set rtt.up (if found true false))))))

(fn rtt_close []
  (when rtt.tcp
    (rtt.tcp:close)
    (set rtt.tcp nil))
  (set rtt.up false))

(fn rtt_buffer []
  (let [buf (vim.api.nvim_create_buf false true)]
    (set rtt.buf buf)
    (set rtt.chan
         (vim.api.nvim_open_term buf
                                 {:on_input (fn [_ _ _ data]
                                              (when rtt.tcp
                                                (rtt.tcp:write data)))}))
    buf))

(fn on_stopped [session]
  (periph_refresh)
  (when (and rtt.buf (not rtt.up))
    ((coroutine.wrap #(rtt_start session)))))

(fn dap_setup []
  (let [dap (require :dap)
        view (require :dap-view)
        sections (. (require :dap-view.setup) :config :winbar :sections)]
    (fn dap.adapters.mcu [callback cfg]
      (let [adapter {:type :executable
                     :command config.gdb
                     :args [:--interpreter=dap
                            :--eval-command
                            "set print pretty on"]}
            start #(server_start #(callback adapter))]
        (if cfg.mcu_load (Utils.build start config.build) (start))))

    (each [_ ft (ipairs config.filetypes)]
      (tset dap.configurations ft (configurations)))
    (view.register_view :peripherals
                        {:label :Peripherals
                         :keymap :P
                         :buffer periph_buffer
                         :action periph_refresh})
    (view.register_view :rtt
                        {:label :RTT
                         :keymap :O
                         :buffer rtt_buffer
                         :action #(let [session (dap.session)]
                                    (when (mcu_session? session)
                                      (on_stopped session)))})
    (when (not (vim.tbl_contains sections :peripherals))
      (view.setup {:winbar {:sections (vim.list_extend (vim.deepcopy sections)
                                                       [:peripherals :rtt])}}))

    (fn dap.listeners.after.event_stopped.mcu [session body]
      (when (mcu_session? session)
        (if (= body.reason :attach)
            ((coroutine.wrap #(on_attach session)))
            (on_stopped session))))

    (fn dap.listeners.after.event_terminated.mcu [session]
      (when (mcu_session? session)
        (rtt_close)
        (set periph.list nil)))))

;; calling it again switches the project to another program
(fn Mcu.setup [opts]
  (set config (vim.tbl_extend :force defaults {:root (vim.fn.getcwd)} opts))
  (set vim.g.build_cmd config.build)
  (set vim.g.run_cmd config.flash)
  (vim.api.nvim_create_autocmd :User
                               {:group (vim.api.nvim_create_augroup :mcu
                                                                    {:clear true})
                                :pattern :DapSetup
                                :callback dap_setup})
  (when package.loaded.dap (dap_setup))
  (vim.api.nvim_create_user_command :McuServer server_toggle
                                    {:bang true
                                     :desc "Start the gdb server and show its log, ! stops it"})
  (when config.serial
    (vim.api.nvim_create_user_command :McuSerial
                                      #(Utils.open_tmp_term config.serial)
                                      {:desc "Serial console in a terminal"})
    (vim.keymap.set :n :<leader>mu ":McuSerial<CR>" {:desc "Mcu serial"}))
  (vim.keymap.set :n :<leader>dm
                  #(do
                     ((. (require :lz.n) :trigger_load) :nvim-dap)
                     ((. (require :dap) :run) (. (configurations) 1)))
                  {:desc "Dap mcu flash and debug"}))
