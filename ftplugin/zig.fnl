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

(fn has_param [params name]
  (accumulate [found false child (params:iter_children)]
    (or found (and (= (child:type) :parameter)
                   (= (text_of (field child :name)) name)))))

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

;; puts `name` in every call zls knows of, so they still compile. in a
;; method obj.f(..) gets it first, T.f(obj, ..) after obj
(fn update_callers [fn_node name]
  (let [name_node (field fn_node :name)
        params (child_of_type fn_node :parameters)
        self? (has_self params)
        count (params:named_child_count)
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
                    (call member?) (call_of ref)]
                (when call
                  (let [args (field call :arguments)
                        n (args:named_child_count)
                        after_self (and self? member? (= n count) (> n 0))
                        (er ec) (if after_self (: (args:named_child 0) :end_)
                                    (let [(ar ac) (args:start)]
                                      (values ar (+ ac 1))))
                        text (if after_self (.. ", " name)
                                 (= n 0) name
                                 (.. name ", "))]
                    (when (not (. edits buf)) (tset edits buf []))
                    (table.insert (. edits buf) [er ec text])))))))))
    ;; from the end of each buffer, so earlier positions still hold
    (var calls 0)
    (each [buf list (pairs edits)]
      (table.sort list
                  (fn [a b]
                    (or (> (. a 1) (. b 1))
                        (and (= (. a 1) (. b 1)) (> (. a 2) (. b 2))))))
      (each [_ [er ec text] (ipairs list)]
        (set calls (+ calls 1))
        (vim.api.nvim_buf_set_text buf er ec er ec [text])))
    (when (> calls 0)
      (vim.notify (.. "added " name " to " calls " call"
                      (if (= calls 1) "" :s))))
    [row col]))

(fn zig_add_param [name type]
  (let [found (current_fn)
        params (and found (child_of_type found :parameters))]
    (if (not params) nil (has_param params name)
        (vim.notify (.. name " is already a parameter"))
        ;; the calls change first, then the function is found again by its
        ;; name, which no call edit moves
        (let [[row col] (update_callers found name)
              parser (vim.treesitter.get_parser 0 :zig)
              _ (parser:parse)
              fn_node (find_ancestor_by_type (parser:named_node_for_range [row
                                                                           col
                                                                           row
                                                                           col])
                                             :function_declaration)
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
                                 (.. param ", ")))))))))

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

(fn zig_toggle [flag label]
  (tset vim.g flag (not (. vim.g flag)))
  (vim.notify (.. label " on save: " (if (. vim.g flag) :on :off))))

(local null_ls (require :null-ls))

;; the function actions only show up with the cursor in a function
(fn in_fn? [params]
  (let [parser (vim.treesitter.get_parser params.bufnr :zig {:error false})]
    (when parser
      (parser:parse)
      (let [node (parser:named_node_for_range [(- params.row 1)
                                               params.col
                                               (- params.row 1)
                                               params.col])]
        (and node
             (or (= (node:type) :function_declaration)
                 (find_ancestor_by_type node :function_declaration)))))))

(fn zig_actions [params]
  (let [toggles [{:title (.. :Toggle_FixAll
                             (if vim.g.zig_fix_all ": On" ": Off"))
                  :action #(zig_toggle :zig_fix_all "fix all")}
                 {:title (.. :Toggle_OrganiseImports
                             (if vim.g.zig_organise_imports ": On" ": Off"))
                  :action #(zig_toggle :zig_organise_imports "organise imports")}]]
    (if (in_fn? params)
        [{:title :Errors :action zig_gen_errs}
         {:title :Add_Io :action #(zig_add_param :io :std.Io)}
         {:title :Add_Allocator
          :action #(zig_add_param :gpa :std.mem.Allocator)}
         {:title :Add_Ctx :action #(zig_add_param :ctx :Context)}
         (unpack toggles)]
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
(set vim.bo.makeprg "zig build $*")
(set vim.bo.errorformat (table.concat ["%f:%l:%c: %trror: %m"
                                       "%f:%l:%c: %tote: %m"
                                       "%+Gerror: '%.%#' failed:"
                                       "%+Gthread %.%# panic: %.%#"
                                       "%-G%\\s%#%.%#/lib/zig/%.%#"
                                       "%\\s%#%f:%l:%c: 0x%*[0-9a-f] in %m"
                                       "%-G%.%#"]
                                      ","))

(set vim.b.build_cmd "zig build")
(set vim.b.run_cmd "zig build run -freference-trace=10 -j$(nproc)")

;; the build.zig needs a test-filter option for -Dtest-filter, the new file
;; template has one. without it zig says invalid option
(set vim.b.test_cmd "zig build test")
(set vim.b.test_filter :-Dtest-filter=)

;; test "name" {} or test decl {}
(fn zig_test_name []
  (let [node (current_node)
        test (if (and node (= (node:type) :test_declaration)) node
                 (find_ancestor_by_type node :test_declaration))
        name (and test (test:named_child 0))]
    (case (and name (name:type))
      :identifier (text_of name)
      :string (let [content (child_of_type name :string_content)]
                (and content (text_of content))))))

(when (and _G.Utils _G.Utils.test_name)
  (tset _G.Utils.test_name :zig zig_test_name))

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
