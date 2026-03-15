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

(when (= 1 (vim.fn.filereadable :build.zig))
  (vim.keymap.set :n :<leader>mr (Utils.mk_tmp_term "zig build run"))
  (vim.keymap.set :n :<leader>mt (Utils.mk_tmp_term "zig build run -- -t")))
