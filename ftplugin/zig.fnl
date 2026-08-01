(set vim.g.zig_fmt_parse_errors 0)
(set vim.g.zig_fmt_autosave 0)

(set vim.g.zig_organise_imports false)
(set vim.g.zig_fix_all false)

(fn bool->str [bool] (if bool :true :false))

(fn table_keys [tbl]
  (local keys [])
  (var n 0)
  (each [key _ (pairs tbl)]
    (set n (+ n 1))
    (set (. keys n) key))
  keys)

(fn insert_at [row col text]
  (let [buf 0
        lnum (+ row 1)
        line (. (vim.api.nvim_buf_get_lines buf (- lnum 1) lnum false) 1)
        before (line:sub 1 col)
        after (line:sub (+ col 1))]
    (vim.api.nvim_buf_set_lines buf (- lnum 1) lnum false
                                [(.. before text after)])))

(fn find_ancestor_by [node ancestor query]
  (if (not= nil node)
      (do
        (var parent (node:parent))
        (while (and (not= nil parent) (not= (query parent) ancestor))
          (set parent (parent:parent)))
        parent)
      nil))

(fn find_ancestor_by_type [node ancestor]
  (find_ancestor_by node ancestor (fn [n] (n:type))))

(fn find_child_by_type [parent child]
  (if (not= nil parent)
      (do
        (var rnode nil)
        (each [node _ (parent:iter_children)
               &until (do
                        (set rnode node)
                        (= (node:type) child))]
          nil)
        rnode)))

;; fn func() void {
; // if i im here
; }
; ->
; fn func(gpa: std.mem.Allocator) void {
;   _ = gpa;
; // if i im here
; }
;
; for gpa, io, ctx (Context, i usually have a struct context {io: Io, gpa: Allocator})

(fn zig_add_param [param]
  (let [cur_node (vim.treesitter.get_node)
        parent_fn (find_ancestor_by_type cur_node :function_declaration)
        params (find_child_by_type parent_fn :parameters)]
    (when params
      (let [(row col _) (params:start)
            text (if (= 2 (params:child_count)) param (.. param ", "))] ; idk y 2 maybe the parens
        (insert_at row (+ 1 col) text)))))

; NOTE dont think i need to prevent multiple params
(local zig_add_io #(zig_add_param "io: std.Io"))
(local zig_add_alloc #(zig_add_param "gpa: std.mem.Allocator"))

(vim.keymap.set :n :<leader>zz zig_add_io {:desc "My zig options"})

; zig error set generation
; fn f() !void {
;     // when i am within the tscontext of is function
;     return error.hello;
; }
;
; // generate
;
; const f_errors = error {
;     a, b, c, d
; };
; fn f() f_errors!void {
;     // when i am within the tscontext of is function
;     if(false) return error.a;
;     if(false) return error.b;
;     if(false) return error.c;
;     return error.d;
; }
; updates error set
(fn zig_gen_errs []
  (let [cur_node (vim.treesitter.get_node)] nil))

(fn def_ui [tbl opts?]
  (vim.ui.select (table_keys tbl) (or opts? {}) (fn [choice] ((. tbl choice)))))

(fn zig_ui []
  (def_ui {:Errors (fn [])
           :Toggle_FixAll #(do
                             (set vim.g.zig_fix_all (not vim.g.zig_fix_all))
                             (vim.print "Zig FixAll is now: " vim.g.zig_fix_all))
           :Add_Io zig_add_io
           :Add_Allocator zig_add_alloc}))

(vim.api.nvim_create_user_command :HermesZig zig_ui {})
; TOOD vim.ui.select
(vim.keymap.set :n :<leader>zu zig_ui {:desc "My zig options"})

(vim.api.nvim_create_autocmd :BufWritePre
                             {:pattern [:*.zig :*.zon]
                              :callback (fn [_]
                                          (when vim.g.zig_organise_imports
                                            (vim.lsp.buf.code_action {:context {:only [:source.organizeImports]}
                                                                      :apply true})))})

(vim.api.nvim_create_autocmd :BufWritePre
                             {:pattern [:*.zig :*.zon]
                              :callback (fn [_]
                                          (when vim.g.zig_fix_all
                                            (vim.lsp.buf.code_action {:context {:only [:source.fixAll]}
                                                                      :apply true})))})

; -- https://zigtools.org/zls/configure/
; -- https://zigtools.org/zls/guides/build-on-save/
(set vim.lsp.config.zls
     {:settings {:zls {:enable_build_on_save true
                       :inlay_hints_hide_redundant_param_names true
                       :inlay_hints_hide_redundant_param_names_last_token true
                       :warn_style true
                       :highlight_global_var_declarations true
                       :build_on_save_args [:-fincremental :-j4]}}})
