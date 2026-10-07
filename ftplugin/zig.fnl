(set vim.g.zig_fmt_parse_errors 0)
(set vim.g.zig_fmt_autosave 0)

;; flipped by hand or by zig_toggle_fixall, a second zig buffer must not
;; reset them
(when (= vim.g.zig_organise_imports nil)
  (set vim.g.zig_organise_imports false))

(when (= vim.g.zig_fix_all nil)
  (set vim.g.zig_fix_all false))

(fn get_from [sr sc er ec] (vim.api.nvim_buf_get_lines 0 sr er false))

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

(fn find_child_by [parent child query]
  (if (not= nil parent)
      (do
        (var rnode nil)
        (each [node _ (parent:iter_children)
               &until (do
                        (set rnode node)
                        (= (query node) child))]
          nil)
        rnode)))

(fn find_child_by_type [parent child]
  (find_child_by parent child (fn [n] (n:type))))

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

(fn current_node []
  ;; reparse first, the tree is stale right after an edit
  (: (vim.treesitter.get_parser) :parse)
  (vim.treesitter.get_node))

(fn zig_add_param [param]
  (let [cur_node (current_node)
        parent_fn (find_ancestor_by_type cur_node :function_declaration)
        params (find_child_by_type parent_fn :parameters)]
    (when params
      (let [(row col _) (params:start)
            text (if (= 2 (params:child_count)) param (.. param ", "))] ; idk y 2 maybe the parens
        (insert_at row (+ 1 col) text)))))

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
  (let [cur_node (current_node)
        parent_fn (find_ancestor_by_type cur_node :function_declaration)]
    (when parent_fn
      (let [body (. (parent_fn:field :body) 1)
            (start_row start_col end_row end_col) (body:range)
            fn_body (get_from start_row start_col (+ end_row 1) end_col)]
        (vim.notify (vim.inspect fn_body))))))

(fn zig_toggle_fixall []
  (set vim.g.zig_fix_all (not vim.g.zig_fix_all))
  (vim.print "Zig FixAll is now: " vim.g.zig_fix_all))

(local null_ls (require :null-ls))

;; this file runs for every zig buffer, the source is global
(when (not (null_ls.is_registered :zig-actions_no_show))
  (null_ls.register {:name :zig-actions_no_show
                     :method [null_ls.methods.CODE_ACTION]
                     :filetypes [:zig]
                     :generator {:fn #[{:title :Errors :action zig_gen_errs}
                                       {:title (.. :Toggle_FixAll
                                                   (if vim.g.zig_fix_all
                                                       ": On"
                                                       ": Off"))
                                        :action zig_toggle_fixall}
                                       {:title :Add_Io
                                        :action #(zig_add_param "io: std.Io")}
                                       {:title :Add_Allocator
                                        :action #(zig_add_param "gpa: std.mem.Allocator")}]}}))

(local group (vim.api.nvim_create_augroup :zig_on_save {:clear false}))
(vim.api.nvim_clear_autocmds {: group :buffer 0})

(vim.api.nvim_create_autocmd :BufWritePre
                             {: group
                              :buffer 0
                              :callback (fn [_]
                                          (when vim.g.zig_organise_imports
                                            (vim.lsp.buf.code_action {:context {:only [:source.organizeImports]}
                                                                      :apply true}))
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
