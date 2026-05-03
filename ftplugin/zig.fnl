;; fn fucn() void {
; // if i im here
; }
; ->
; fn fucn(gpa: std.heap.Allocator) void {
;   _ = gpa;
; // if i im here
; }

(fn zig_add_gpa []
  (local node (vim.treesitter.get_node))
  nil)

(vim.api.nvim_create_user_command :HermesZigAddGPA zig_add_gpa {})
(vim.keymap.set :n :<leader>za zig_add_gpa
                {:desc "Add Zig allocator param to current function"})

; (when (= 1 (vim.fn.filereadable :build.zig))
;   (vim.keymap.set :n :<leader>mr (Utils.mk_tmp_term "zig build run"))
;   (vim.keymap.set :n :<leader>mt (Utils.mk_tmp_term "zig build run -- -t")))

(set vim.g.zig_fmt_parse_errors 0)
(set vim.g.zig_fmt_autosave 0)

(set vim.g.zig_bad false)

(vim.api.nvim_create_autocmd :BufWritePre
                             {:pattern [:*.zig :*.zon]
                              :callback (fn [_]
                                          (when vim.g.zig_bad
                                            (do
                                              (vim.lsp.buf.code_action {:context {:only [:source.fixAll]}
                                                                        :apply true})
                                              (vim.lsp.buf.code_action {:context {:only [:source.organizeImports]}
                                                                        :apply true}))))})

; -- https://zigtools.org/zls/configure/
; -- https://zigtools.org/zls/guides/build-on-save/
(set vim.lsp.config.zls
     {:settings {:zls {:enable_build_on_save true
                       :inlay_hints_hide_redundant_param_names true
                       :inlay_hints_hide_redundant_param_names_last_token true
                       :warn_style true
                       :highlight_global_var_declarations true
                       :build_on_save_args [:-fincremental :-j4]}}})
