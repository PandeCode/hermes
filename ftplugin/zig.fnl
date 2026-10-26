(set vim.g.zig_fmt_parse_errors 0)
(set vim.g.zig_fmt_autosave 0)

;; flipped by hand or by zig_toggle, a second zig buffer must not
;; reset them
(when (= vim.g.zig_organise_imports nil)
  (set vim.g.zig_organise_imports false))

(when (= vim.g.zig_fix_all nil)
  (set vim.g.zig_fix_all false))

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

;; parameters has no field name in tree-sitter-zig
(fn child_of_type [node t]
  (accumulate [found nil child (node:iter_children)]
    (or found (when (= (child:type) t) child))))

(fn text_of [node]
  (vim.treesitter.get_node_text node 0))

(fn field [node name]
  (. (node:field name) 1))

(fn current_node []
  ;; reparse first, the tree is stale right after an edit. no zig parser
  ;; gives nil here
  (let [parser (vim.treesitter.get_parser 0 :zig {:error false})]
    (when parser
      (parser:parse)
      (vim.treesitter.get_node))))

;; the cursor can be on `fn` or `pub`, where the node is the function itself
(fn current_fn []
  (let [node (current_node)
        fn_node (if (and node (= (node:type) :function_declaration)) node
                    (find_ancestor_by_type node :function_declaration))]
    (if (not fn_node) (vim.notify "not in a function" vim.log.levels.WARN)
        (not (field fn_node :body)) (vim.notify "extern function, no body"
                                                vim.log.levels.WARN)
        fn_node)))

(fn line_indent [row]
  (: (. (vim.api.nvim_buf_get_lines 0 row (+ row 1) false) 1) :match "^%s*"))

(fn replace_node [node text]
  (let [(sr sc er ec) (node:range)]
    (vim.api.nvim_buf_set_text 0 sr sc er ec (vim.split text "\n"))))

(fn insert_text [row col text]
  (vim.api.nvim_buf_set_text 0 row col row col (vim.split text "\n")))

(fn param_index [params name]
  (var found nil)
  (for [i 0 (- (params:named_child_count) 1) &until found]
    (let [p (params:named_child i)]
      (when (and (= (p:type) :parameter) (= (text_of (field p :name)) name))
        (set found i))))
  found)

;; the range that takes an item and one comma next to it out of a list
(fn list_item_range [node]
  (let [nxt (node:next_named_sibling)
        prev (node:prev_named_sibling)
        (sr sc er ec) (node:range)]
    (if nxt (let [(nr nc) (nxt:start)] [sr sc nr nc])
        prev (let [(pr pc) (prev:end_)] [pr pc er ec])
        [sr sc er ec])))

;; fn func() void {
; // if i im here
; }
; ->
; fn func(gpa: std.mem.Allocator) void {
;   _ = gpa;
; // if i im here
; }
;
; the discard keeps the new param compiling until it is used, then zig asks
; for it to go
(fn uses [node name]
  (accumulate [found false child (node:iter_children)]
    (or found (and (= (child:type) :identifier) (= (text_of child) name))
        (uses child name))))

(fn has_self [params]
  (let [first (params:named_child 0)]
    (and first (= (text_of (field first :name)) :self) first)))

;; the call around a reference to the function: f(..) or x.f(..)
(fn call_of [ref]
  (let [parent (and ref (ref:parent))
        callee (if (and parent (= (parent:type) :field_expression)) parent ref)
        call (and callee (callee:parent))]
    (when (and call (= (call:type) :call_expression)
               (= (. (call:field :function) 1) callee))
      (values call (not= callee ref)))))

;; runs `edit` on every call to the function zls knows of, in every file.
;; edit gets the call and whether it was obj.f(..), and returns the range to
;; replace and the text for it, or nil
(fn edit_callers [fn_node edit what]
  (let [name_node (field fn_node :name)
        (row col) (name_node:start)
        edits {}]
    (each [_ client (ipairs (vim.lsp.get_clients {:bufnr 0 :name :zls}))]
      (let [enc client.offset_encoding
            line (. (vim.api.nvim_buf_get_lines 0 row (+ row 1) false) 1)
            req {:textDocument (vim.lsp.util.make_text_document_params 0)
                 :position {:line row
                            :character (vim.str_utfindex line enc col false)}
                 :context {:includeDeclaration false}}
            uri (vim.uri_from_bufnr 0)
            ask #(let [res (client:request_sync :textDocument/references req
                                                2000 0)]
                   (or (and res res.result) []))
            first (ask)
            ;; zls only looks in other files once it knows which build the
            ;; file is in, and the first request is what makes it find out
            refs (if (and (vim.startswith (text_of fn_node) "pub ")
                          (: (vim.iter first) :all #(= $.uri uri)))
                     (do
                       (vim.wait 300)
                       (ask))
                     first)]
        (each [_ loc (ipairs refs)]
          (let [buf (vim.uri_to_bufnr loc.uri)
                _ (vim.fn.bufload buf)
                parser (vim.treesitter.get_parser buf :zig {:error false})
                r loc.range.start.line
                text (. (vim.api.nvim_buf_get_lines buf r (+ r 1) false) 1)
                c (vim.str_byteindex text enc loc.range.start.character false)]
            (when parser
              (parser:parse)
              (let [ref (parser:named_node_for_range [r c r c])
                    (call member?) (call_of ref)
                    change (and call (edit call member?))]
                (when change
                  (when (not (. edits buf)) (tset edits buf []))
                  (table.insert (. edits buf) change))))))))
    ;; from the end of each buffer, so earlier positions still hold
    (var calls 0)
    (each [buf list (pairs edits)]
      (table.sort list
                  (fn [a b]
                    (or (> (. a 1) (. b 1))
                        (and (= (. a 1) (. b 1)) (> (. a 2) (. b 2))))))
      (each [_ [sr sc er ec text] (ipairs list)]
        (set calls (+ calls 1))
        (vim.api.nvim_buf_set_text buf sr sc er ec (vim.split text "\n"))))
    (when (> calls 0)
      (vim.notify (.. what " " calls " call" (if (= calls 1) "" :s))))
    [row col]))

;; puts `name` in a call so it still compiles. in a method obj.f(..) gets it
;; first, T.f(obj, ..) after obj
(fn add_arg [name self? count]
  (fn [call member?]
    (let [args (field call :arguments)
          n (args:named_child_count)
          after_self (and self? member? (= n count) (> n 0))
          (er ec) (if after_self (: (args:named_child 0) :end_)
                      (let [(ar ac) (args:start)]
                        (values ar (+ ac 1))))]
      [er
       ec
       er
       ec
       (if after_self (.. ", " name)
           (= n 0) name
           (.. name ", "))])))

;; takes the argument for parameter `index` out of a call. obj.f(..) has no
;; argument for self, so one less
(fn remove_arg [index self? count]
  (fn [call member?]
    (let [args (field call :arguments)
          n (args:named_child_count)
          i (if (and self? member? (< n count)) (- index 1) index)
          arg (and (>= i 0) (< i n) (args:named_child i))]
      (when arg
        (let [[sr sc er ec] (list_item_range arg)]
          [sr sc er ec ""])))))

;; the function again after edits, by the position of its name, which no
;; call edit moves
(fn refind_fn [row col]
  (let [parser (vim.treesitter.get_parser 0 :zig)]
    (parser:parse)
    (find_ancestor_by_type (parser:named_node_for_range [row col row col])
                           :function_declaration)))

(fn add_param [found name type]
  (let [params (child_of_type found :parameters)
        [row col] (edit_callers found
                                (add_arg name (has_self params)
                                         (params:named_child_count))
                                (.. "added " name " to"))
        fn_node (refind_fn row col)
        params (child_of_type fn_node :parameters)
        body (field fn_node :body)
        (_ _ end_row) (body:range)
        (brow bcol) (body:start)
        (prow pcol) (params:start)
        indent (line_indent (fn_node:start))
        one_line (= brow end_row)
        param (.. name ": " type)]
    ;; the body comes after the params, edit it first so the params
    ;; position still holds. a recursive call already uses the name,
    ;; and zig rejects a discard of a used parameter
    (when (not (uses body name))
      (insert_text brow (+ bcol 1)
                   (.. "\n" indent "    _ = " name ";"
                       (if one_line (.. "\n" indent) ""))))
    ;; after self in methods, so obj.method() calls stay valid
    (let [first (has_self params)]
      (if first
          (let [(srow scol) (first:end_)]
            (insert_text srow scol (.. ", " param)))
          (insert_text prow (+ pcol 1)
                       (if (= 0 (params:named_child_count)) param
                           (.. param ", ")))))))

;; the other way: out of the calls, the discard add_param put in, and the
;; parameter list
(fn remove_param [found name index]
  (let [params (child_of_type found :parameters)
        [row col] (edit_callers found
                                (remove_arg index (has_self params)
                                            (params:named_child_count))
                                (.. "took " name " out of"))
        fn_node (refind_fn row col)
        body (field fn_node :body)
        (brow _) (body:start)
        (_ _ erow) (body:range)]
    ;; from the bottom, so the rows above, the params among them, still hold
    (for [r erow brow -1]
      (when (: (. (vim.api.nvim_buf_get_lines 0 r (+ r 1) false) 1) :match
               (.. "^%s*_ = " name ";%s*$"))
        (vim.api.nvim_buf_set_lines 0 r (+ r 1) false [])))
    (let [[sr sc er ec] (list_item_range (: (child_of_type fn_node :parameters)
                                            :named_child index))]
      (vim.api.nvim_buf_set_text 0 sr sc er ec [""]))
    ;; a body that was {} before add_param split it goes back to {}
    (let [body (field (refind_fn row col) :body)]
      (when (: (text_of body) :match "^{%s*}$")
        (replace_node body "{}"))
      (when (uses body name)
        (vim.notify (.. name " is still used in the function")
                    vim.log.levels.WARN)))))

(fn zig_toggle_param [name type]
  (let [found (current_fn)
        params (and found (child_of_type found :parameters))
        index (and params (param_index params name))]
    (if (not params) nil
        index (remove_param found name index)
        (add_param found name type))))

;; zig error set generation
; fn f() !void {
;     // when i am within the tscontext of is function
;     return error.hello;
; }
;
; // generate
;
; const f_errors = error{ hello };
; fn f() f_errors!void {
;     return error.hello;
; }
;
; running it again adds new errors to f_errors and keeps the ones there, so
; errors that only come in through try can be added by hand
(fn returned_errors [body]
  (let [names []]
    (fn walk [node in_return]
      (each [child (node:iter_children)]
        (case (child:type)
          :function_declaration nil
          (where :error_type in_return)
          (table.insert names (text_of (child:named_child 0)))
          t (walk child (or in_return (= t :return_expression))))))

    (walk body false)
    names))

(fn set_members [set_node]
  (icollect [child (set_node:iter_children)]
    (when (= (child:type) :identifier) (text_of child))))

(fn merge [existing found]
  (let [seen (collect [_ n (ipairs existing)] n true)
        out (icollect [_ n (ipairs existing)] n)]
    (each [_ n (ipairs found)]
      (when (not (. seen n))
        (tset seen n true)
        (table.insert out n)))
    out))

;; the error set declaration named `name` next to the function
(fn find_set_decl [fn_node name]
  (accumulate [found nil child (: (fn_node:parent) :iter_children)]
    (or found (when (and (= (child:type) :variable_declaration)
                         (= (text_of (child:named_child 0)) name)
                         (= (: (child:named_child 1) :type)
                            :error_set_declaration))
                (child:named_child 1)))))

;; above the function and its /// doc comment
(fn insert_set_decl [fn_node decl]
  (var row (fn_node:start))
  (while (and (> row 0) (: (. (vim.api.nvim_buf_get_lines 0 (- row 1) row false)
                              1) :match "^%s*///"))
    (set row (- row 1)))
  (vim.api.nvim_buf_set_lines 0 row row false
                              [(.. (line_indent (fn_node:start)) decl)]))

(fn zig_gen_errs []
  (let [fn_node (current_fn)]
    (when fn_node
      (let [name (.. (text_of (field fn_node :name)) :_errors)
            ret (field fn_node :type)
            err (and (= (ret:type) :error_union_type) (field ret :error))
            decl_set (find_set_decl fn_node name)
            inline_set (and err (= (err:type) :error_set_declaration) err)
            found (returned_errors (field fn_node :body))
            members (merge (if decl_set (set_members decl_set)
                               inline_set (set_members inline_set)
                               []) found)
            ;; zig fmt style, error{a} and error{ a, b }
            set_text (if (= 1 (length members))
                         (.. "error{" (. members 1) "}")
                         (.. "error{ " (table.concat members ", ") " }"))
            pub (if (vim.startswith (text_of fn_node) "pub ") "pub " "")]
        (if (= 0 (length members))
            (vim.notify "no return error.X in this function")
            (and err (not inline_set) (not= (text_of err) name))
            (vim.notify (.. "returns " (text_of err) ", left alone"))
            (do
              ;; the return type comes after where the declaration goes, so
              ;; change it first
              (if (not err)
                  (replace_node ret
                                (.. name "!"
                                    (if (= (ret:type) :error_union_type)
                                        (text_of (field ret :ok))
                                        (text_of ret))))
                  inline_set
                  (replace_node inline_set name))
              (if decl_set
                  (replace_node decl_set set_text)
                  (insert_set_decl fn_node
                                   (.. pub "const " name " = " set_text ";")))))))))

;; the generated `f_errors!T` and its `const f_errors = error{..};`, nil
;; for any other return type
(fn generated_set [fn_node]
  (let [name (.. (text_of (field fn_node :name)) :_errors)
        ret (field fn_node :type)
        err (and (= (ret:type) :error_union_type) (field ret :error))
        errset (and err (= (text_of err) name) (find_set_decl fn_node name))]
    (when errset
      (values errset ret))))

;; back to an inferred `!T`, the set goes
(fn zig_remove_errs []
  (let [fn_node (current_fn)]
    (when fn_node
      (let [(errset ret) (generated_set fn_node)]
        (if (not errset)
            (vim.notify "no generated error set on this function")
            (let [(sr _ er _) (: (errset:parent) :range)]
              ;; the return type is below the set, change it first
              (replace_node ret (.. "!" (text_of (field ret :ok))))
              (vim.api.nvim_buf_set_lines 0 sr (+ er 1) false [])))))))

;; the call under the cursor, f(..) or x.f(..). on `try` it is the one after
(fn call_at [node]
  (if (not node) nil
      (and (= (node:type) :try_expression)
           (= (: (node:named_child 0) :type) :call_expression)) (node:named_child 0)
      (= (node:type) :call_expression) node
      (find_ancestor_by_type node :call_expression)))

(fn tried? [call]
  (let [parent (call:parent)]
    (and parent (= (parent:type) :try_expression) parent)))

(fn zig_toggle_try []
  (let [call (call_at (current_node))
        try (and call (tried? call))]
    (if (not call) (vim.notify "not in a call") try
        (let [(tr tc) (try:start)
              (cr cc) (call:start)]
          (vim.api.nvim_buf_set_text 0 tr tc cr cc [""]))
        (let [(cr cc) (call:start)]
          (insert_text cr cc "try ")))))

(fn zig_toggle [flag label]
  (tset vim.g flag (not (. vim.g flag)))
  (vim.notify (.. label " on save: " (if (. vim.g flag) :on :off))))

(local null_ls (require :null-ls))

;; the function actions only show up with the cursor in a function, and
;; each says what it does there: Add_Io or Remove_Io and so on
(fn node_at [params]
  (let [parser (vim.treesitter.get_parser params.bufnr :zig {:error false})
        (r c) (values (- params.row 1) params.col)]
    (when parser
      (parser:parse)
      (parser:named_node_for_range [r c r c]))))

(fn fn_at [node]
  (if (and node (= (node:type) :function_declaration)) node
      (find_ancestor_by_type node :function_declaration)))

(local param_actions [[:Io :io :std.Io]
                      [:Allocator :gpa :std.mem.Allocator]
                      [:Ctx :ctx :Context]])

(fn fn_actions [fn_node node]
  (let [params (child_of_type fn_node :parameters)
        call (call_at node)
        actions (if (generated_set fn_node)
                    [{:title :Update_Errors :action zig_gen_errs}
                     {:title :Remove_Errors :action zig_remove_errs}]
                    [{:title :Add_Errors :action zig_gen_errs}])]
    (when call
      (table.insert actions
                    {:title (if (tried? call) :Remove_Try :Add_Try)
                     :action zig_toggle_try}))
    (each [_ [label name type] (ipairs param_actions)]
      (table.insert actions
                    {:title (.. (if (param_index params name) :Remove_ :Add_)
                                label)
                     :action #(zig_toggle_param name type)}))
    actions))

(fn zig_actions [params]
  (let [node (node_at params)
        fn_node (fn_at node)
        toggles [{:title (.. :Toggle_FixAll
                             (if vim.g.zig_fix_all ": On" ": Off"))
                  :action #(zig_toggle :zig_fix_all "fix all")}
                 {:title (.. :Toggle_OrganiseImports
                             (if vim.g.zig_organise_imports ": On" ": Off"))
                  :action #(zig_toggle :zig_organise_imports "organise imports")}]]
    (if (and fn_node (field fn_node :body))
        (doto (fn_actions fn_node node)
          (table.insert (. toggles 1))
          (table.insert (. toggles 2)))
        toggles)))

;; this file runs for every zig buffer, the source is global
(when (not (null_ls.is_registered :zig-actions_no_show))
  (null_ls.register {:name :zig-actions_no_show
                     :method [null_ls.methods.CODE_ACTION]
                     :filetypes [:zig]
                     :generator {:fn zig_actions}}))

(local group (vim.api.nvim_create_augroup :zig_on_save {:clear false}))
(vim.api.nvim_clear_autocmds {: group :buffer 0})

;; vim.lsp.buf.code_action is async, its edits land after the write and leave
;; the buffer modified, so ask zls and apply the edits before writing
(fn apply_source_action [buf kind]
  (each [_ client (ipairs (vim.lsp.get_clients {:bufnr buf :name :zls}))]
    (let [params {:textDocument (vim.lsp.util.make_text_document_params buf)
                  :range {:start {:line 0 :character 0}
                          :end {:line (vim.api.nvim_buf_line_count buf)
                                :character 0}}
                  :context {:only [kind] :diagnostics []}}
          res (client:request_sync :textDocument/codeAction params 1000 buf)]
      (each [_ action (ipairs (or (and res res.result) []))]
        (when action.edit
          (vim.lsp.util.apply_workspace_edit action.edit client.offset_encoding))))))

(vim.api.nvim_create_autocmd :BufWritePre
                             {: group
                              :buffer 0
                              :callback (fn [args]
                                          (when vim.g.zig_organise_imports
                                            (apply_source_action args.buf
                                                                 :source.organizeImports))
                                          (when vim.g.zig_fix_all
                                            (apply_source_action args.buf
                                                                 :source.fixAll)))})

;; :make, <leader>mb, <leader>mr and <leader>mt run zig build and fill the
;; quickfix list. kept are the error and note lines, a failed test or panic
;; with its stack trace minus the frames in zig's std. the build tree, source
;; excerpts and reference trace go
(set vim.bo.errorformat (table.concat ["%f:%l:%c: %trror: %m"
                                       "%f:%l:%c: %tote: %m"
                                       "%+Gerror: '%.%#' failed:"
                                       "%+Gthread %.%# panic: %.%#"
                                       "%-G%\\s%#%.%#/lib/zig/%.%#"
                                       "%\\s%#%f:%l:%c: 0x%*[0-9a-f] in %m"
                                       "%-G%.%#"]
                                      ","))

(set vim.b.test_cmd "zig build test")
(set vim.b.test_filter :-Dtest-filter=)

;; the build.zig zig build would use, the one up from the cwd
(fn build_file []
  (. (vim.fs.find :build.zig {:upward true :path (vim.fn.getcwd)}) 1))

;; a zig script starts with //usr/bin/env sh -c ... and builds itself when
;; sh runs it, the `script` snippet makes one
(fn script? [buf]
  (let [first (. (vim.api.nvim_buf_get_lines buf 0 1 false) 1)]
    (and first (vim.startswith first "//usr/bin/env ") true)))

;; a script runs as itself, its compile errors and panics come back from the
;; terminal into quickfix. with no build.zig, :make, <leader>mb and
;; <leader>mr work on the file alone. looked up again when the cwd changes,
;; the buffer comes back or it is written
(fn set_build_cmds [buf]
  (let [file (vim.fn.shellescape (vim.api.nvim_buf_get_name buf) 1)]
    (if (script? buf)
        (do
          (tset vim.bo buf :makeprg (.. "sh " file))
          (tset vim.b buf :build_cmd nil)
          (tset vim.b buf :run_cmd (.. "sh " file)))
        (build_file)
        (do
          (tset vim.bo buf :makeprg "zig build $*")
          (tset vim.b buf :build_cmd "zig build")
          (tset vim.b buf :run_cmd
                "zig build run -freference-trace=10 -j$(nproc)"))
        (do
          (tset vim.bo buf :makeprg (.. "zig build-exe -fno-emit-bin " file))
          (tset vim.b buf :build_cmd (.. "zig build-exe -fno-emit-bin " file))
          (tset vim.b buf :run_cmd (.. "zig run -freference-trace=10 " file))))))

(set_build_cmds (vim.api.nvim_get_current_buf))

;; one for all zig buffers, made again (and cleared) by each new one
(vim.api.nvim_create_autocmd [:BufEnter :BufWritePost :DirChanged]
                             {:group (vim.api.nvim_create_augroup :zig_build_cmds
                                                                  {:clear true})
                              :callback #(when (= vim.bo.filetype :zig)
                                           (set_build_cmds (vim.api.nvim_get_current_buf)))})

;; test "name" {} or test decl {}
(fn test_name []
  (let [node (current_node)
        test (if (and node (= (node:type) :test_declaration)) node
                 (find_ancestor_by_type node :test_declaration))
        name (and test (test:named_child 0))]
    (case (and name (name:type))
      :identifier (text_of name)
      :string (let [content (child_of_type name :string_content)]
                (and content (text_of content))))))

;; zig build test when the file is in the build and build.zig has the
;; test-filter option (the new file template does). otherwise zig test on the
;; file alone, in a terminal at the bottom, which works for a file outside any
;; project too
(fn zig_test_at []
  (let [name (test_name)
        file (vim.api.nvim_buf_get_name 0)
        build (build_file)
        in_build (and build
                      (vim.startswith file (.. (vim.fs.dirname build) "/")))
        filters (and in_build
                     (: (table.concat (vim.fn.readfile build) "\n") :find
                        "\"test-filter\"" 1 true))]
    (if (and in_build (or filters (not name))) {: name}
        {:term (.. "zig test " (vim.fn.shellescape file 1)
                   (if name
                       (.. " --test-filter " (vim.fn.shellescape name 1))
                       ""))})))

(when (and _G.Utils _G.Utils.test_at)
  (tset _G.Utils.test_at :zig zig_test_at))

;; pick a step from zig build -l, it becomes the run_cmd so <leader>mr does it
;; again
(fn zig_pick_step []
  (vim.system [:zig :build :-l] {:text true}
              (vim.schedule_wrap (fn [out]
                                   (if (not= 0 out.code)
                                       (vim.notify out.stderr
                                                   vim.log.levels.ERROR)
                                       (let [steps (icollect [_ line (ipairs (vim.split out.stdout
                                                                                        "\n"))]
                                                     (line:match "^%s+(%S+)"))]
                                         (vim.ui.select steps
                                                        {:prompt "zig build step"}
                                                        (fn [step]
                                                          (when step
                                                            (set vim.g.run_cmd
                                                                 (.. "zig build "
                                                                     step))
                                                            (_G.Utils.run))))))))))

(vim.keymap.set :n :<leader>ms zig_pick_step
                {:buffer 0 :desc "zig build step into run_cmd"})
