vim.loader.enable()
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
Fennel = nil
do
  local ok_3f, _fennel = pcall(require("fennel").install)
  if ok_3f then
    Fennel = _fennel
  else
  end
end
package.preload["fnl.utils"] = package.preload["fnl.utils"] or function(...)
  local function curry(f, n, _3fargs)
    local args = (_3fargs or {n = 0})
    local function _2_(...)
      local inner = table.pack(...)
      local n_2a = (args.n + inner.n)
      do
        table.move(inner, 1, inner.n, (args.n + 1))
        inner["n"] = n_2a
      end
      table.move(args, 1, args.n, 1, inner)
      if (n_2a >= n) then
        return f((_G.unpack or table.unpack)(inner, 1, n_2a))
      else
        return curry(f, n, inner)
      end
    end
    return _2_
  end
  local function range_next_2a(_4_, x)
    local start = _4_[1]
    local _end = _4_[2]
    local step = _4_[3]
    if (step == 0) then
      if (start ~= _end) then
        return x
      else
        return nil
      end
    else
      local x0 = (x + step)
      if (((0 < step) and (x0 < _end)) or ((0 > step) and (x0 > _end))) then
        return x0
      else
        return nil
      end
    end
  end
  local function range(...)
    local start, _end, step
    do
      local case_8_, case_9_, case_10_ = select("#", ...), ...
      if (case_8_ == 0) then
        start, _end, step = 0, (1 / 0), 1
      elseif ((case_8_ == 1) and true) then
        local _3fend = case_9_
        start, _end, step = 0, _3fend, 1
      elseif ((case_8_ == 2) and true and true) then
        local _3fstart = case_9_
        local _3fend = case_10_
        start, _end, step = _3fstart, _3fend, 1
      else
        local _ = case_8_
        start, _end, step = ...
      end
    end
    return range_next_2a, {start, _end, step}, (start - step)
  end
  Utils = {}
  Utils.open_tmp_term = function(cmd, fb)
    vim.cmd(("botright split | terminal " .. cmd))
    local bufnr = vim.api.nvim_win_get_buf(0)
    vim.api.nvim_set_option_value("buflisted", false, {buf = bufnr})
    vim.api.nvim_set_option_value("bufhidden", "wipe", {buf = bufnr})
    local h = math.floor((vim.o.lines / 4))
    vim.cmd(("resize " .. h))
    vim.cmd("wincmd p")
    if (fb ~= nil) then
      return fb(bufnr)
    else
      return nil
    end
  end
  Utils.bind_term = function(bind, cmd, fb)
    local function _13_()
      return Utils.open_tmp_term(cmd, fb)
    end
    return vim.keymap.set("n", bind, _13_)
  end
  Utils.bind_job = function(bind, cmd)
    local function _14_()
      return vim.fn.jobstart({"sh", "-c", cmd})
    end
    return vim.keymap.set("n", bind, _14_)
  end
  Utils.bind_tmux = function(bind, cmd)
    return Utils.bind_job(bind, ("tmux split-window -l 10 '" .. cmd .. " && exit 0 || tmux last-pane & tmux copy-mode & cat'; tmux last-pane"))
  end
  Utils.bind_term("<leader>to", "tmux kill-pane -a")
  local function table_keys(tbl)
    local keys = {}
    local n = 0
    for key, _ in pairs(tbl) do
      n = (n + 1)
      keys[n] = key
    end
    return keys
  end
  local function def_ui(tbl, opts_3f)
    local function _15_(choice)
      if choice then
        return tbl[choice]()
      else
        return nil
      end
    end
    return vim.ui.select(table_keys(tbl), (opts_3f or {}), _15_)
  end
  local function runner(cmd)
    local function _17_()
      return Utils.bind_term("<leader>mr", cmd)
    end
    return _17_
  end
  local function _18_()
    return def_ui({bind_nix = runner("nix-instantiate --show-trace --eval ./%"), bind_zig = runner("zig build run -freference-trace=10 -j$(nproc)"), bind_run = runner("make run"), bind_exe = runner("./%")})
  end
  return vim.keymap.set("n", "<leader>bb", _18_)
end
require("fnl.utils")
package.preload["fnl.options"] = package.preload["fnl.options"] or function(...)
  vim.filetype.add({extension = {fnl = "fennel"}})
  local function _19_()
    vim.bo.commentstring = "// %s"
    return nil
  end
  vim.api.nvim_create_autocmd("Filetype", {pattern = {"wgsl", "glsl"}, callback = _19_})
  vim.g.no_plugin_maps = true
  for _, plugin in ipairs({"netrwPlugin", "netrw", "gzip", "zip", "zipPlugin", "tar", "tarPlugin", "getscript", "getscriptPlugin", "vimball", "vimballPlugin", "2html_plugin", "logipat", "rrhelper", "spellfile_plugin", "matchit"}) do
    vim.g[("loaded_" .. plugin)] = 1
  end
  for k, v in pairs({inccommand = "split", breakindent = true, number = true, relativenumber = true, termguicolors = true, cursorline = true, signcolumn = "yes", colorcolumn = "80", list = true, listchars = "tab:\226\134\146 ,lead:\194\183,trail:\194\183,nbsp:\226\144\163", pumblend = 20, winblend = 20, showmatch = true, scrolloff = 8, sidescrolloff = 8, laststatus = 3, expandtab = true, shiftwidth = 4, tabstop = 4, softtabstop = 4, smartindent = true, autoindent = true, smarttab = true, wrap = true, linebreak = true, formatoptions = "jcroqlnt", conceallevel = 1, virtualedit = "block", completeopt = "menu,menuone,noselect", hlsearch = true, incsearch = true, ignorecase = true, smartcase = true, gdefault = true, undofile = true, hidden = true, confirm = true, autoread = true, fileencoding = "utf-8", mouse = "a", updatetime = 100, timeoutlen = 500, ttimeoutlen = 10, history = 1000, cmdheight = 1, splitbelow = true, splitright = true, guifont = "FantasqueSansM Nerd Font:h14", guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175", visualbell = true, title = true, shortmess = "filnxtToOFIc", spell = true, spelllang = "en_us", synmaxcol = 240, redrawtime = 1000, wildignore = table.concat({"*.pyc", "*_build/*", "**/coverage/*", "**/Debug/*", "**/build/*", "**/node_modules/*", "**/android/*", "**/ios/*", "**/.git/*", "*.lock", "*.aux", "*.bbl", "*.bcf", "*.blg", "*.fdb_latexmk", "*.fls", "*.log", "*.pdf", "*.run.xml", "*.synctex.gz", "*.tex", "*.toc", "*.DS_Store", "*.class", "*.out"}, ","), wildmode = "longest:full,full", wildmenu = true, backspace = "indent,eol,start", showcmd = true, ruler = true, backup = false, showmode = false, swapfile = false, writebackup = false}) do
    vim.o[k] = v
  end
  return nil
end
require("fnl.options")
package.preload["fnl.keymaps"] = package.preload["fnl.keymaps"] or function(...)
  local function n(a_2_auto, b_3_auto, c_4_auto)
    return vim.keymap.set("n", a_2_auto, b_3_auto, c_4_auto)
  end
  local function c(a_2_auto, b_3_auto, c_4_auto)
    return vim.keymap.set("c", a_2_auto, b_3_auto, c_4_auto)
  end
  local function v(a_2_auto, b_3_auto, c_4_auto)
    return vim.keymap.set("v", a_2_auto, b_3_auto, c_4_auto)
  end
  local function i(a_2_auto, b_3_auto, c_4_auto)
    return vim.keymap.set("i", a_2_auto, b_3_auto, c_4_auto)
  end
  local function x(a_2_auto, b_3_auto, c_4_auto)
    return vim.keymap.set("x", a_2_auto, b_3_auto, c_4_auto)
  end
  local function a(a_2_auto, b_3_auto, c_4_auto)
    return vim.keymap.set("", a_2_auto, b_3_auto, c_4_auto)
  end
  local noremap = {noremap = true}
  local noremap_expr = {noremap = true, expr = true}
  local noremap_silent = {silent = true, noremap = true}
  do
    n("<esc>", "<cmd>nohlsearch<cr>")
    local function _20_()
      vim.cmd.edit("%")
      return vim.treesitter.start()
    end
    n("<leader>fe", _20_)
    n("<leader>fs", "<cmd>w<cr>")
    n("g.", "`.")
    n("<leader>co", "<cmd>copen<cr>")
    n("<leader>cc", "<cmd>cclose<cr>")
    n("<leader>re", "<cmd>reg<cr>")
    n("<leader>fw", "<cmd>noautocmd w<cr>")
    n("<leader>li", "<cmd>lsp info<cr>", noremap_silent)
    n("<leader>lq", "<cmd>lsp stop<cr>", noremap_silent)
    n("<leader>lr", "<cmd>lsp restart<cr>", noremap_silent)
    n("<leader>le", "<cmd>lsp enable<cr>", noremap_silent)
    n("<leader>ld", "<cmd>lsp disable<cr>", noremap_silent)
    n("<leader>me", vim.cmd.messages, nil)
    n("<leader>bp", vim.cmd.bp, noremap_silent)
    n("<leader>bn", vim.cmd.bn, noremap_silent)
    n("<leader>bo", "<cmd>%bd|e#<cr>", noremap_silent)
    n("<A-d>", vim.cmd.bd, noremap_silent)
    n("<leader>c<leader>", "<cmd>normal gcc<cr>", noremap_silent)
    v("<leader>c<leader>", "gc", noremap_silent)
    n("<leader>`", "<cmd>e#<cr>", noremap_silent)
    n("<leader>gf", "<cmd>e <cfile><cr>")
    n("<leader><F2>", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/<Left>")
    local function _21_()
      if (vim.fn.mode() == "V") then
        return "^<C-v>I"
      else
        return "I"
      end
    end
    x("I", _21_, {expr = true})
    local function _23_()
      if (vim.fn.mode() == "V") then
        return "$<C-v>A"
      else
        return "A"
      end
    end
    x("A", _23_, {expr = true})
    n("<Home>", "(col('.') == matchend(getline('.'), '^\\s*')+1 ? '0' : '^')", noremap_expr)
    n("<End>", "(col('.') == match(getline('.'), '\\s*$') ? '$' : 'g_')", noremap_expr)
    v("<End>", "(col('.') == match(getline('.'), '\\s*$') ? '$h' : 'g_')", noremap_expr)
    i("<Home>", "<C-o><Home>")
    i("<End>", "<C-o><End>")
    n("gg", "gg0", noremap)
    a("G", "G<End>", noremap)
    a("Y", "y$", noremap)
    n("<leader>w", "<c-w>", noremap)
    n("<leader>w|", "<cmd>vsplit<cr>", noremap)
    n("<leader>w_", "<cmd>split<cr>", noremap)
    n("<leader>j", ":<c-u>put!=repeat([''],v:count)<bar>']+1<cr>", noremap_silent)
    n("<leader>k", ":<c-u>put =repeat([''],v:count)<bar>'[-1<cr>", noremap_silent)
    n("<c-c>", "\"+y", noremap)
    v("<c-c>", "\"+y", noremap)
    n("<c-v>", "\"+p", noremap)
    i("<c-v>", "<c-r>+", noremap)
    c("<c-v>", "<c-r>+", noremap)
    n("<c-x>", "\"+dd", noremap)
    v("<c-x>", "\"+d", noremap)
    n("n", "nzzzv", noremap)
    n("N", "Nzzzv", noremap)
    n("J", "mzJ`z", noremap)
    i(",", ",<c-g>u", noremap)
    i(".", ".<c-g>u", noremap)
    i("!", "!<c-g>u", noremap)
    i("?", "?<c-g>u", noremap)
    i("[", "[<c-g>u", noremap)
    i("]", "]<c-g>u", noremap)
    i("(", "(<c-g>u", noremap)
    i(")", ")<c-g>u", noremap)
    i("{", "{<c-g>u", noremap)
    i("}", "}<c-g>u", noremap)
    i("\"", "\"<c-g>u", noremap)
    n("<", "v<gv<ESC>", noremap)
    n(">", "v>gv<ESC>", noremap)
    v("<", "<gv", noremap)
    v(">", ">gv", noremap)
    v("`", "<ESC>`>a`<ESC>`<i`<ESC>", noremap)
    v("(", "<ESC>`>a)<ESC>`<i(<ESC>", noremap)
    v("'", "<ESC>`>a'<ESC>`<i'<ESC>", noremap)
    v("<c-{>", "<ESC>`>a}<ESC>`<i{<ESC>", noremap)
    v(")", "<ESC>`>a)<ESC>`<i(<ESC>", noremap)
    v("]", "<ESC>`>a]<ESC>`<i[<ESC>", noremap)
    v("<c-}>", "<ESC>`>a}<ESC>`<i{<ESC>", noremap)
    x("/", "<Esc>/\\%V")
    i("<c-f>", "<c-g>u<Esc>[s1z=gi<c-g>u", noremap)
  end
  return nil
end
require("fnl.keymaps")
package.preload["fnl.autocmds"] = package.preload["fnl.autocmds"] or function(...)
  local function _25_()
    local data = vim.fn.stdpath("data")
    local cwd = vim.fn.getcwd()
    cwd = (vim.fs.root(cwd, ".git") or cwd)
    local cwd_b64 = vim.base64.encode(cwd)
    local file = vim.fs.joinpath(data, "project_shada", cwd_b64)
    vim.fn.mkdir(vim.fs.dirname(file), "p")
    return file
  end
  vim.opt.shadafile = _25_()
  local function _26_()
    local line = vim.fn.line
    if ((line("'\"") > 0) and (line("'\"") <= line("$"))) then
      vim.fn.execute("normal! g`\"")
    else
    end
    return nil
  end
  vim.api.nvim_create_autocmd("BufReadPost", {callback = _26_})
  vim.api.nvim_create_autocmd("TextYankPost", {callback = vim.hl.on_yank})
  local function _28_(args)
    if ((vim.bo[args.buf].buftype == "") and not args.match:find("://", 1, true)) then
      vim.fn.mkdir(vim.fn.fnamemodify(args.match, ":p:h"), "p")
    else
    end
    return nil
  end
  vim.api.nvim_create_autocmd("BufWritePre", {pattern = "*", callback = _28_})
  local function _30_()
    vim.opt.relativenumber = false
    return nil
  end
  vim.api.nvim_create_autocmd("InsertEnter", {pattern = "*", callback = _30_})
  local function _31_()
    vim.opt.relativenumber = true
    return nil
  end
  vim.api.nvim_create_autocmd("InsertLeave", {pattern = "*", callback = _31_})
  vim.cmd("\n\n\nif argc() > 1\n\tsilent blast \" load last buffer\n\tsilent bfirst \" switch back to the first\nendif\n\n")
  local function _32_()
    local filename = vim.fn.expand("%")
    vim.cmd("!git add %")
    return vim.notify(("Git added '" .. filename .. "'"))
  end
  vim.api.nvim_create_user_command("Gitadd", _32_, {})
  local function _33_()
    local filename = vim.fn.expand("%")
    vim.cmd("!chmod +x %")
    return vim.notify(("Given execution rights to '" .. filename .. "'"))
  end
  vim.api.nvim_create_user_command("Chmodx", _33_, {})
  local function _34_()
    return vim.cmd("!rm -f %")
  end
  vim.api.nvim_create_user_command("Rmf", _34_, {})
  for from, to in pairs({W = "w", Q = "q", WQ = "wq", Wq = "wq", WQA = "wqa", Wqa = "wqa", QA = "qa", Qa = "qa", E = "e", gitadd = "Gitadd", chmodx = "Chmodx", rmf = "Rmf", fnl = "Fnl"}) do
    local function _35_()
      if ((vim.fn.getcmdtype() == ":") and (vim.fn.getcmdline() == from)) then
        return to
      else
        return from
      end
    end
    vim.keymap.set("ca", from, _35_, {expr = true})
  end
  vim.diagnostic.config({virtual_text = true, virtual_lines = {current_line = true}, underline = true, update_in_insert = false})
  local og_virt_text = nil
  local og_virt_line = nil
  local function _37_()
    if (og_virt_line == nil) then
      og_virt_line = vim.diagnostic.config().virtual_lines
    else
    end
    if not (og_virt_line and og_virt_line.current_line) then
      if og_virt_text then
        vim.diagnostic.config({virtual_text = og_virt_text})
        og_virt_text = nil
      else
      end
      return
    else
    end
    if (og_virt_text == nil) then
      og_virt_text = vim.diagnostic.config().virtual_text
    else
    end
    local lnum = (vim.api.nvim_win_get_cursor(0)[1] - 1)
    if vim.tbl_isempty(vim.diagnostic.get(0, {lnum = lnum})) then
      return vim.diagnostic.config({virtual_text = og_virt_text})
    else
      return vim.diagnostic.config({virtual_text = false})
    end
  end
  vim.api.nvim_create_autocmd({"CursorMoved", "DiagnosticChanged"}, {group = vim.api.nvim_create_augroup("diagnostic_only_virtlines", {}), callback = _37_})
  local function _43_()
    pcall(vim.diagnostic.show)
    return nil
  end
  vim.api.nvim_create_autocmd("ModeChanged", {group = vim.api.nvim_create_augroup("diagnostic_redraw", {}), callback = _43_})
  local function _44_(args)
    vim.fn.delete(args.match)
    return nil
  end
  return vim.api.nvim_create_autocmd("BufWritePost", {pattern = {"f", "fe"}, callback = _44_})
end
require("fnl.autocmds")
package.preload["fnl.plugins"] = package.preload["fnl.plugins"] or function(...)
  vim.cmd("packadd nvim.undotree")
  vim.cmd("packadd nvim.difftool")
  require("oil").setup((nil or {}))
  vim.keymap.set("n", "-", "<cmd>Oil<CR>", {noremap = true, desc = "Open Parent Directory"})
  vim.keymap.set("n", "<leader>-", "<cmd>Oil .<CR>", {noremap = true, desc = "Open nvim root directory"})
  local function _45_(args)
    if pcall(vim.treesitter.start, args.buf) then
      vim.bo[args.buf]["indentexpr"] = "v:lua.require'nvim-treesitter'.indentexpr()"
      return nil
    else
      return nil
    end
  end
  vim.api.nvim_create_autocmd("FileType", {group = vim.api.nvim_create_augroup("treesitter_start", {}), callback = _45_})
  local ts_ctx = require("treesitter-context")
  ts_ctx.setup({enable = true, multiwindow = true})
  local function _47_()
    return ts_ctx.go_to_context(vim.v.count1)
  end
  vim.keymap.set("n", "[c", _47_, {silent = true})
  local ts_obj = require("nvim-treesitter-textobjects")
  ts_obj.setup({select = {lookahead = true}, move = {set_jumps = true}})
  local ts_select = require("nvim-treesitter-textobjects.select")
  local ts_move = require("nvim-treesitter-textobjects.move")
  local ts_swap = require("nvim-treesitter-textobjects.swap")
  for key, capture in pairs({aa = "@parameter.outer", ia = "@parameter.inner", af = "@function.outer", ["if"] = "@function.inner", ac = "@class.outer", ic = "@class.inner"}) do
    local function _48_()
      return ts_select.select_textobject(capture, "textobjects")
    end
    vim.keymap.set({"x", "o"}, key, _48_)
  end
  for key, _49_ in pairs({["]m"] = {"goto_next_start", "@function.outer"}, ["]]"] = {"goto_next_start", "@class.outer"}, ["]M"] = {"goto_next_end", "@function.outer"}, ["]["] = {"goto_next_end", "@class.outer"}, ["[m"] = {"goto_previous_start", "@function.outer"}, ["[["] = {"goto_previous_start", "@class.outer"}, ["[M"] = {"goto_previous_end", "@function.outer"}, ["[]"] = {"goto_previous_end", "@class.outer"}}) do
    local move = _49_[1]
    local capture = _49_[2]
    local function _50_()
      return ts_move[move](capture, "textobjects")
    end
    vim.keymap.set({"n", "x", "o"}, key, _50_)
  end
  local function _51_()
    return ts_swap.swap_next("@parameter.inner")
  end
  vim.keymap.set("n", "<leader>a", _51_)
  local function _52_()
    return ts_swap.swap_previous("@parameter.inner")
  end
  vim.keymap.set("n", "<leader>A", _52_)
  vim.keymap.set("n", "<c-space>", "van", {remap = true})
  vim.keymap.set("x", "<c-space>", "an", {remap = true})
  vim.keymap.set("x", "<M-space>", "in", {remap = true})
  require("snacks").setup({bigfile = {enabled = true}, dashboard = {enabled = false}, explorer = {enabled = true}, indent = {enabled = true}, input = {enabled = true}, picker = {enabled = true}, notifier = {enabled = true}, quickfile = {enabled = true}, scope = {enabled = true}, scroll = {enabled = true}, statuscolumn = {enabled = true}, words = {enabled = true}})
  local function sk(c)
    local function _53_()
      return Snacks.picker[c]()
    end
    return _53_
  end
  for _, v in ipairs({{"<leader>ff", sk("files"), "Find Files"}, {"<leader>fr", sk("grep"), "Grep"}, {"<leader>fm", sk("marks"), "Marks"}, {"<leader>fn", sk("man"), "Man"}, {"<leader><space>", sk("smart"), "Smart Find Files"}, {"<leader>fb", sk("buffers"), "Buffers"}, {"<leader>ch", sk("cliphist"), "cliphist"}, {"<leader>fll", sk("loclist"), "loclist"}, {"<leader>fq", sk("qflist"), "qflist"}, {"<leader>fld", sk("lsp_declarations"), "lsp_declarations"}, {"<leader>fle", sk("lsp_definitions"), "lsp_definitions"}, {"<leader>fli", sk("lsp_implementations"), "lsp_implementations"}, {"<leader>flr", sk("lsp_references"), "lsp_references"}, {"<leader>fls", sk("lsp_symbols"), "lsp_symbols"}, {"<leader>nh", Snacks.notifier.hide, "Notifier Hide"}, {"<leader>ns", Snacks.notifier.show_history, "Notifier Show"}}) do
    vim.keymap.set("n", v[1], v[2], {desc = v[3]})
  end
  require("noice").setup(({lsp = {override = {["vim.lsp.util.convert_input_to_markdown_lines"] = true, ["vim.lsp.util.stylize_markdown"] = true}}, presets = {command_palette = true, long_message_to_split = true, lsp_doc_border = true, bottom_search = false, inc_rename = false}} or {}))
  require("mini.icons").setup((nil or {}))
  require("mini.cursorword").setup((nil or {}))
  require("mini.pairs").setup((nil or {}))
  require("mini.align").setup((nil or {}))
  require("mini.move").setup((nil or {}))
  require("mini.splitjoin").setup((nil or {}))
  require("mini.trailspace").setup((nil or {}))
  local miniclue = require("mini.clue")
  require("mini.clue").setup(({triggers = {{mode = {"n", "x"}, keys = "<leader>"}, {mode = {"n", "x"}, keys = "g"}, {mode = {"n", "x"}, keys = "z"}, {mode = {"n", "x"}, keys = "<c-w>"}, {mode = {"n", "x"}, keys = "'"}, {mode = {"n", "x"}, keys = "`"}, {mode = {"n", "x"}, keys = "\""}}, clues = {miniclue.gen_clues.square_brackets(), miniclue.gen_clues.builtin_completion(), miniclue.gen_clues.marks(), miniclue.gen_clues.registers(), miniclue.gen_clues.windows(), miniclue.gen_clues.z(), miniclue.gen_clues.g()}} or {}))
  local hipatterns = require("mini.hipatterns")
  local function _54_(_, _0, data)
    return MiniHipatterns.compute_hex_color_group(data.full_match:gsub("0x", "#"), "bg")
  end
  require("mini.hipatterns").setup(({highlighters = {fixme = {pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme"}, error = {pattern = "%f[%w]()ERROR()%f[%W]", group = "MiniHipatternsFixme"}, err = {pattern = "%f[%w]()ERR()%f[%W]", group = "MiniHipatternsFixme"}, bug = {pattern = "%f[%w]()BUG()%f[%W]", group = "MiniHipatternsFixme"}, hack = {pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack"}, warn = {pattern = "%f[%w]()WARN()%f[%W]", group = "MiniHipatternsHack"}, todo = {pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo"}, note = {pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote"}, info = {pattern = "%f[%w]()INFO()%f[%W]", group = "MiniHipatternsNote"}, base00 = {pattern = "base00", group = "GP_base00"}, base01 = {pattern = "base01", group = "GP_base01"}, base02 = {pattern = "base02", group = "GP_base02"}, base03 = {pattern = "base03", group = "GP_base03"}, base04 = {pattern = "base04", group = "GP_base04"}, base05 = {pattern = "base05", group = "GP_base05"}, base06 = {pattern = "base06", group = "GP_base06"}, base07 = {pattern = "base07", group = "GP_base07"}, base08 = {pattern = "base08", group = "GP_base08"}, base09 = {pattern = "base09", group = "GP_base09"}, base0A = {pattern = "base0A", group = "GP_base0A"}, base0B = {pattern = "base0B", group = "GP_base0B"}, base0C = {pattern = "base0C", group = "GP_base0C"}, base0D = {pattern = "base0D", group = "GP_base0D"}, base0E = {pattern = "base0E", group = "GP_base0E"}, base0F = {pattern = "base0F", group = "GP_base0F"}, hex_color = hipatterns.gen_highlighter.hex_color(), hex_num = {pattern = "0x%x%x%x%x%x%x%f[%X]", group = _54_, extmark_opts = {priority = 200}}}} or {}))
  local mini_s = require("mini.surround")
  local ts_input = mini_s.gen_spec.input.treesitter
  local function _55_()
    local n_star = MiniSurround.user_input("Number of * to find")
    local many_star = string.rep("%*", (tonumber(n_star) or 1))
    return {(many_star .. "().-()" .. many_star)}
  end
  local function _56_()
    local n_star = MiniSurround.user_input("Number of * to output")
    local many_star = string.rep("%*", (tonumber(n_star) or 1))
    return {left = many_star, right = many_star}
  end
  mini_s.setup({mappings = {add = "ys", delete = "ds", find = "", find_left = "", highlight = "", replace = "cs", update_n_lines = "", suffix_last = "", suffix_next = ""}, search_method = "cover_or_next", custom_surroundings = {f = {input = ts_input({outer = "@call.outer", inner = "@call.inner"})}, b = {input = ts_input({outer = "@block.outer", inner = "@block.inner"})}, [")"] = {output = {left = "( ", right = " )"}}, ["*"] = {input = _55_, output = _56_}}})
  vim.keymap.del("x", "ys")
  vim.keymap.set("x", "S", ":<C-u>lua MiniSurround.add('visual')<CR>", {silent = true})
  vim.keymap.set("n", "yss", "ys_", {remap = true})
  local function _57_()
    MiniTrailspace.trim()
    return MiniTrailspace.trim_last_lines()
  end
  vim.api.nvim_create_autocmd({"BufWritePre"}, {pattern = "*", callback = _57_})
  local hermes_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
  require("blink.indent").setup((nil or {}))
  local function _58_(ctx)
    local kind_icon, _, _0 = MiniIcons.get("lsp", ctx.kind)
    return kind_icon
  end
  local function _59_(ctx)
    local _, hl, _0 = MiniIcons.get("lsp", ctx.kind)
    return hl
  end
  local function _60_(ctx)
    local _, hl, _0 = MiniIcons.get("lsp", ctx.kind)
    return hl
  end
  require("blink.cmp").setup(({fuzzy = {implementation = "prefer_rust"}, keymap = {["<C-k>"] = {}}, signature = {enabled = true, window = {show_documentation = true}}, sources = {providers = {snippets = {opts = {search_paths = {(hermes_dir .. "/snippets")}}}}}, completion = {menu = {draw = {treesitter = {"lsp"}, columns = {{"kind_icon"}, {"label", "label_description", gap = 1}, {"kind"}}, components = {kind_icon = {text = _58_, highlight = _59_}, kind = {highlight = _60_}}}}, documentation = {auto_show = true}}} or {}))
  local parinfer_filetypes = {"racket", "lisp", "wat", "wasm", "fennel"}
  local function parinfer_apply()
    local function _61_()
      if vim.b.parinfer_on then
        return "ParinferOn"
      else
        return "ParinferOff"
      end
    end
    pcall(vim.cmd, _61_())
    vim.cmd.redrawstatus()
    return nil
  end
  local function parinfer_set(on)
    vim.b.parinfer_on = on
    return parinfer_apply()
  end
  local function parinfer_on()
    return parinfer_set(true)
  end
  local function parinfer_off()
    return parinfer_set(false)
  end
  local function parinfer_toggle()
    return parinfer_set(not vim.b.parinfer_on)
  end
  vim.keymap.set("n", "<leader>po", parinfer_on, {desc = "parinfer-on"})
  vim.keymap.set("n", "<leader>pf", parinfer_off, {desc = "parinfer-off"})
  vim.keymap.set("n", "<leader>pt", parinfer_toggle, {desc = "parinfer-toggle"})
  local function _62_()
    return parinfer_set(vim.tbl_contains(parinfer_filetypes, vim.bo.filetype))
  end
  vim.api.nvim_create_autocmd("FileType", {callback = _62_})
  vim.api.nvim_create_autocmd("BufEnter", {callback = parinfer_apply})
  local lz = require("lz.n")
  local function _63_()
    return lz.trigger_load("nvim-dap")
  end
  local function _64_()
    return require("neogen").generate()
  end
  local function _65_()
    return require("neogen").setup((nil or {}))
  end
  return lz.load({{"zig.vim", ft = "zig"}, {"vlime", ft = "lisp"}, {"rustaceanvim", ft = "rust", before = _63_}, {"vim-sleuth", event = {"BufReadPost", "BufNewFile"}}, {"vim-wakatime", event = "DeferredUIEnter"}, {"vim-visual-multi", event = "DeferredUIEnter"}, {"vim-wordmotion", event = "DeferredUIEnter"}, {"refactoring.nvim", cmd = "Refactor"}, {"neogen", cmd = "Neogen", keys = {{"<leader>nf", _64_}}, after = _65_}})
end
require("fnl.plugins")
package.preload["fnl.theme"] = package.preload["fnl.theme"] or function(...)
  local stylix_dir = vim.fs.normalize("~/.config/stylix")
  local function get_base16()
    local ok_3f, val = pcall(dofile, (stylix_dir .. "/style.lua"))
    if ok_3f then
      return val
    else
      return {base00 = "#1a1b26", base01 = "#16161e", base02 = "#2f3549", base03 = "#444b6a", base04 = "#787c99", base05 = "#a9b1d6", base06 = "#cbccd1", base07 = "#d5d6db", base08 = "#c0caf5", base09 = "#a9b1d6", base0A = "#0db9d7", base0B = "#9ece6a", base0C = "#b4f9f8", base0D = "#2ac3de", base0E = "#bb9af7", base0F = "#f7768e"}
    end
  end
  local function is_dark(_hex)
    local hex = _hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    local brightness = ((0.2126 * r) + (0.7152 * g) + (0.0722 * b))
    return (brightness < 128)
  end
  local IsTransparent = false
  local function apply_theme(base16)
    require("mini.base16").setup({use_cterm = true, palette = base16})
    IsTransparent = false
    vim.cmd(("hi LineNr guifg=" .. base16.base0E .. "\n" .. "hi LspInlayHint guifg=" .. base16.base04 .. "\n"))
    for group, color in pairs(base16) do
      local fg_color
      if is_dark(color) then
        fg_color = "#ffffff"
      else
        fg_color = "#000000"
      end
      vim.cmd(string.format("highlight GP_%s guifg=%s guibg=%s gui=NONE", group, fg_color, color))
    end
    return vim.api.nvim_exec_autocmds("ColorScheme", {})
  end
  apply_theme(get_base16())
  if vim.env.THEME_WATCH then
    local fse = vim.uv.new_fs_event()
    local function _68_(err, filename)
      if (not err and (filename == "style.lua")) then
        apply_theme(get_base16())
        return vim.notify("Switched Themes", vim.log.levels.INFO)
      else
        return nil
      end
    end
    vim.uv.fs_event_start(fse, stylix_dir, {}, vim.schedule_wrap(_68_))
    vim.notify(("Now watching " .. stylix_dir .. "/style.lua for external changes"), vim.log.levels.INFO)
  else
  end
  local function set_hl(gp, opt)
    return vim.api.nvim_set_hl(0, gp, opt)
  end
  local function ToggleBackground()
    local palette = require("mini.base16").config.palette
    if IsTransparent then
      set_hl("Normal", {fg = palette.base05, bg = palette.base00})
      set_hl("LineNr", {fg = palette.base03, bg = palette.base00})
      set_hl("SignColumn", {fg = palette.base03, bg = palette.base00})
      set_hl("NonText", {fg = palette.base02, bg = palette.base00})
      IsTransparent = false
      return nil
    else
      set_hl("Normal", {bg = "NONE"})
      set_hl("LineNr", {fg = palette.base03, bg = "NONE"})
      set_hl("SignColumn", {fg = palette.base03, bg = "NONE"})
      set_hl("NonText", {fg = palette.base02, bg = "NONE"})
      IsTransparent = true
      return nil
    end
  end
  return vim.keymap.set("n", "<LEADER>bt", ToggleBackground, {noremap = true, silent = true})
end
require("fnl.theme")
package.preload["fnl.statusline"] = package.preload["fnl.statusline"] or function(...)
  Statusline = {}
  local function sbcl_pid()
    local ps = io.popen("pidof sbcl")
    local pids = ps:read()
    ps:close()
    if pids then
      local found = false
      for _, pid in ipairs(vim.fn.split(pids, " ")) do
        if found then break end
        local ok_3f, args = pcall(vim.fn.readfile, ("/proc/" .. pid .. "/cmdline"))
        if (ok_3f and vim.endswith((args[1] or ""), "start-vlime.lisp\n")) then
          found = pid
        else
        end
      end
      return found
    else
      return false
    end
  end
  local sbcl_running_3f = false
  local function _74_()
    if (vim.bo.filetype == "lisp") then
      sbcl_running_3f = sbcl_pid()
      return nil
    else
      return nil
    end
  end
  vim.api.nvim_create_autocmd({"BufEnter", "FocusGained", "CursorHold"}, {callback = _74_})
  local function set_highlights()
    vim.api.nvim_set_hl(0, "ParinferOn", {fg = MiniBase16.config.palette.base0B, bold = true})
    return vim.api.nvim_set_hl(0, "ParinferOff", {fg = MiniBase16.config.palette.base03})
  end
  set_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {callback = set_highlights})
  local function get_attached_clients()
    local buf_clients = vim.lsp.get_clients({bufnr = 0})
    if (#buf_clients == 0) then
      return "No client active"
    else
      local buf_ft = vim.bo.filetype
      local buf_client_names = {}
      local function add_name(name)
        if (not vim.endswith(name, "_no_show") and not vim.tbl_contains(buf_client_names, name)) then
          return table.insert(buf_client_names, name)
        else
          return nil
        end
      end
      for _, client in pairs(buf_clients) do
        add_name(client.name)
      end
      do
        local ok_3f, null_ls = pcall(require, "null-ls")
        if ok_3f then
          for _, source in ipairs(null_ls.get_sources()) do
            if source._validated then
              for ft_name, ft_active in pairs(source.filetypes) do
                if ((ft_name == buf_ft) and ft_active) then
                  add_name(source.name)
                else
                end
              end
            else
            end
          end
        else
        end
      end
      if (("lisp" == buf_ft) and sbcl_running_3f) then
        table.insert(buf_client_names, "sbcl")
      else
      end
      return ("[" .. table.concat(buf_client_names, ", ") .. "]")
    end
  end
  local function lsp()
    local count = {}
    local levels = {errors = "Error", warnings = "Warn", info = "Info", hints = "Hint"}
    for k, level in pairs(levels) do
      count[k] = vim.tbl_count(vim.diagnostic.get(0, {severity = level}))
    end
    local _82_
    if (count.errors ~= 0) then
      _82_ = ("%#" .. "DiagnosticError" .. "#" .. tostring(("\239\129\151 " .. count.errors)) .. "%*")
    else
      _82_ = ""
    end
    local _84_
    if (count.warnings ~= 0) then
      _84_ = ("%#" .. "DiagnosticWarn" .. "#" .. tostring(("\239\129\177 " .. count.warnings)) .. "%*")
    else
      _84_ = ""
    end
    local _86_
    if (count.hints ~= 0) then
      _86_ = ("%#" .. "DiagnosticHint" .. "#" .. tostring(("\239\129\154 " .. count.hints)) .. "%*")
    else
      _86_ = ""
    end
    local _88_
    if (count.info ~= 0) then
      _88_ = ("%#" .. "DiagnosticInfo" .. "#" .. tostring(("\239\129\153 " .. count.info)) .. "%*")
    else
      _88_ = ""
    end
    return (_82_ .. _84_ .. _86_ .. _88_ .. "%#Normal#")
  end
  local function git()
    local d = vim.b.gitsigns_status_dict
    if d then
      local _90_
      if (d.added and (d.added > 0)) then
        _90_ = ("%#" .. "GitSignsAdd" .. "#" .. tostring(("+ " .. d.added .. " ")) .. "%*")
      else
        _90_ = ""
      end
      local _92_
      if (d.changed and (d.changed > 0)) then
        _92_ = ("%#" .. "GitSignsChange" .. "#" .. tostring(("~ " .. d.changed .. " ")) .. "%*")
      else
        _92_ = ""
      end
      local _94_
      if (d.removed and (d.removed > 0)) then
        _94_ = ("%#" .. "GitSignsDelete" .. "#" .. tostring(("- " .. d.removed .. " ")) .. "%*")
      else
        _94_ = ""
      end
      return (("%#" .. "GitSignsAdd" .. "#" .. tostring((" \238\156\165 " .. d.head)) .. "%*") .. " " .. _90_ .. _92_ .. _94_)
    else
      return ""
    end
  end
  local function fun()
    local lisp_3f = vim.tbl_contains({"racket", "lisp", "fennel", "scheme"}, vim.bo.filetype)
    local icon = MiniIcons.get("filetype", "scheme")
    if (1 == vim.g.parinfer_enabled) then
      return ("%#ParinferOn#" .. icon .. " ()%*")
    else
      if lisp_3f then
        return ("%#ParinferOff#" .. icon .. " ()%*")
      else
        return ""
      end
    end
  end
  local function selection_size(m)
    if vim.tbl_contains({"v", "V", "\22"}, m) then
      return (" c:" .. vim.fn.wordcount().visual_chars .. " l:" .. (1 + math.abs((vim.fn.line("v") - vim.fn.line(".")))))
    else
      return ""
    end
  end
  local function mode()
    local modes = {n = {"(\227\131\187_\227\131\187)", "base0D", "base00"}, i = {"(\227\129\163\226\128\162\204\128\207\137\226\128\162\204\129)\227\129\163", "base0B", "base00"}, v = {"(\225\151\146\225\151\168\225\151\149)", "base0E", "base00"}, V = {"(\225\151\146\225\151\168\225\151\149)\226\148\129", "base0E", "base00"}, ["\22"] = {"(\225\151\146\225\151\168\225\151\149)\226\150\136", "base0E", "base00"}, c = {"(\224\184\135 \226\128\162\204\128_\226\128\162\204\129)\224\184\135", "base0A", "base00"}, R = {"(\235\136\136_\235\136\136)", "base08", "base00"}}
    local m = vim.fn.mode()
    local p = MiniBase16.config.palette
    local _let_100_ = (modes[m] or {"?", "base05", "base00"})
    local text = _let_100_[1]
    local fg = _let_100_[2]
    local bg = _let_100_[3]
    vim.api.nvim_set_hl(0, "StatusLineMode", {fg = p[fg], bg = p[bg], bold = true})
    return ("%#StatusLineMode#" .. text .. selection_size(m) .. "%*")
  end
  local function recording()
    local reg = vim.fn.reg_recording()
    if (reg == "") then
      return ""
    else
      return ("%#" .. "WarningMsg" .. "#" .. tostring((" (\226\128\162_\226\128\162) @" .. reg)) .. "%*")
    end
  end
  local function searchcount()
    local ok_3f, sc = pcall(vim.fn.searchcount)
    if (ok_3f and sc.total and (sc.total > 0)) then
      return ("%#Comment#[" .. sc.current .. "/" .. sc.total .. "]%*")
    else
      return ""
    end
  end
  local function wordcount()
    if vim.tbl_contains({"markdown", "text", "org"}, vim.bo.filetype) then
      return ("%#" .. "Comment" .. "#" .. tostring((" " .. vim.fn.wordcount().words .. "w")) .. "%*")
    else
      return ""
    end
  end
  local function nix_shell()
    local env = os.getenv("IN_NIX_SHELL")
    if env then
      local _104_
      do
        local pv_105_, pv_106_ = MiniIcons.get("os", "nixos")
        local icon_2_auto,hl_3_auto = pv_105_, pv_106_
        local _107_
        if hl_3_auto then
          _107_ = ("%#" .. hl_3_auto .. "#")
        else
          _107_ = ""
        end
        _104_ = (_107_ .. (icon_2_auto or "") .. "%*")
      end
      return (_104_ .. ("%#" .. "Comment" .. "#" .. tostring(env) .. "%*"))
    else
      return ""
    end
  end
  local function filename()
    local buf = vim.api.nvim_buf_get_name(0)
    local rel = vim.fn.fnamemodify(buf, ":~:.")
    local name = vim.fn.fnamemodify(buf, ":t")
    local dir = vim.fn.fnamemodify(rel, ":h")
    local icon, hl = MiniIcons.get("file", name)
    local _110_
    if (dir == ".") then
      _110_ = ""
    else
      _110_ = (dir .. "/")
    end
    local _112_
    if hl then
      _112_ = ("%#" .. hl .. "#")
    else
      _112_ = ""
    end
    local _114_
    if vim.bo.modified then
      _114_ = ("%#" .. "WarningMsg" .. "#" .. tostring("\226\151\143") .. "%*")
    else
      _114_ = ""
    end
    local _116_
    if vim.bo.readonly then
      _116_ = ("%#" .. "DiagnosticError" .. "#" .. tostring("\240\159\148\146") .. "%*")
    else
      _116_ = ""
    end
    return ("%#Comment#" .. _110_ .. "%*" .. (_112_ .. ((icon .. " " .. name) or "") .. "%*") .. " " .. _114_ .. _116_)
  end
  Statusline.active = function()
    local _118_
    do
      local pv_119_, pv_120_ = MiniIcons.get("file", (vim.fn.expand("%") or "default"))
      local icon_2_auto,hl_3_auto = pv_119_, pv_120_
      local _121_
      if hl_3_auto then
        _121_ = ("%#" .. hl_3_auto .. "#")
      else
        _121_ = ""
      end
      _118_ = (_121_ .. (icon_2_auto or "") .. "%*")
    end
    return (mode() .. " " .. recording() .. " " .. git() .. " " .. filename() .. " " .. lsp() .. "%=" .. get_attached_clients() .. "%=" .. searchcount() .. " " .. fun() .. " " .. nix_shell() .. " " .. _118_ .. " " .. "%{&filetype != '' ? &filetype : 'text'} " .. " " .. wordcount() .. " " .. "[%P %l:%c]")
  end
  Statusline.inactive = function()
    return "%#Comment# %t%*"
  end
  local group = vim.api.nvim_create_augroup("Statusline", {clear = true})
  local function _123_()
    vim.opt_local.statusline = "%!v:lua.Statusline.active()"
    return nil
  end
  vim.api.nvim_create_autocmd({"WinEnter", "BufEnter"}, {group = group, callback = _123_})
  local function _124_()
    vim.opt_local.statusline = "%!v:lua.Statusline.inactive()"
    return nil
  end
  vim.api.nvim_create_autocmd({"WinLeave", "BufLeave"}, {group = group, callback = _124_})
  local function _125_()
    return vim.cmd.redrawstatus()
  end
  return vim.defer_fn(_125_, 1000)
end
require("fnl.statusline")
package.preload["fnl.tabline"] = package.preload["fnl.tabline"] or function(...)
  local function _126_()
    vim.cmd.redrawtabline()
    return nil
  end
  vim.api.nvim_create_autocmd({"TermRequest", "ModeChanged"}, {desc = "Refresh tabline", callback = _126_})
  Tabline = {}
  local function merge_icon_hl(src, dst)
    local fg = vim.api.nvim_get_hl(0, {name = src, link = false}).fg
    local bg = vim.api.nvim_get_hl(0, {name = dst, link = false}).bg
    local group = (src .. dst)
    if (fg and bg) then
      vim.api.nvim_set_hl(0, group, {fg = fg, bg = bg})
    else
    end
    return group
  end
  local function set_highlights()
    local p = MiniBase16.config.palette
    vim.api.nvim_set_hl(0, "TabActive", {fg = p.base05, bg = p.base02, bold = true})
    vim.api.nvim_set_hl(0, "TabInactive", {fg = p.base00, bg = p.base02})
    vim.api.nvim_set_hl(0, "TabModified", {fg = p.base08, bg = p.base02})
    return vim.api.nvim_set_hl(0, "TabLocked", {fg = p.base09, bg = p.base02})
  end
  set_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {callback = set_highlights})
  local function listed_bufs()
    local function _128_(b)
      return (vim.api.nvim_buf_is_valid(b) and (1 == vim.fn.buflisted(b)) and (vim.api.nvim_buf_get_name(b) ~= ""))
    end
    return vim.tbl_filter(_128_, vim.api.nvim_list_bufs())
  end
  local function buf_diag(buf)
    local e = #vim.diagnostic.get(buf, {severity = vim.diagnostic.severity.ERROR})
    local w = #vim.diagnostic.get(buf, {severity = vim.diagnostic.severity.WARN})
    local _129_
    if (e > 0) then
      _129_ = ("%#" .. "DiagnosticSignError" .. "# " .. tostring(e) .. "%*")
    else
      _129_ = ""
    end
    local _131_
    if (w > 0) then
      _131_ = ("%#" .. "DiagnosticSignWarn" .. "# " .. tostring(w) .. "%*")
    else
      _131_ = ""
    end
    return (_129_ .. _131_)
  end
  local function workspace_diag()
    local e = #vim.diagnostic.get(nil, {severity = vim.diagnostic.severity.ERROR})
    local w = #vim.diagnostic.get(nil, {severity = vim.diagnostic.severity.WARN})
    local h = #vim.diagnostic.get(nil, {severity = vim.diagnostic.severity.HINT})
    local i = #vim.diagnostic.get(nil, {severity = vim.diagnostic.severity.INFO})
    local _133_
    if (e > 0) then
      _133_ = ("%#" .. "DiagnosticSignError" .. "# " .. tostring(e) .. "%*")
    else
      _133_ = ""
    end
    local _135_
    if (w > 0) then
      _135_ = ("%#" .. "DiagnosticSignWarn" .. "# " .. tostring(w) .. "%*")
    else
      _135_ = ""
    end
    local _137_
    if (h > 0) then
      _137_ = ("%#" .. "DiagnosticSignHint" .. "# " .. tostring(h) .. "%*")
    else
      _137_ = ""
    end
    local _139_
    if (i > 0) then
      _139_ = ("%#" .. "DiagnosticSignInfo" .. "# " .. tostring(i) .. "%*")
    else
      _139_ = ""
    end
    return (_133_ .. _135_ .. _137_ .. _139_)
  end
  Tabline["goto"] = function(n)
    local buf = listed_bufs()[n]
    if buf then
      return vim.api.nvim_set_current_buf(buf)
    else
      return nil
    end
  end
  Tabline.render = function()
    local current = vim.api.nvim_get_current_buf()
    local bufs = listed_bufs()
    local result = ""
    for i, buf in ipairs(bufs) do
      local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
      local icon, icon_hl = MiniIcons.get("file", name)
      local modified = (1 == vim.fn.getbufvar(buf, "&modified"))
      local readonly = (1 == vim.fn.getbufvar(buf, "&readonly"))
      local nowrite = not (1 == vim.fn.getbufvar(buf, "&modifiable"))
      local locked = (readonly or nowrite)
      local active = (buf == current)
      local hl
      if locked then
        hl = "TabLocked"
      elseif active then
        hl = "TabActive"
      elseif modified then
        hl = "TabModified"
      else
        hl = "TabInactive"
      end
      local icon_group = merge_icon_hl(icon_hl, hl)
      local status
      local _143_
      if locked then
        _143_ = " \243\176\140\190"
      else
        _143_ = ""
      end
      local _145_
      if modified then
        _145_ = " \226\151\143"
      else
        _145_ = ""
      end
      status = (_143_ .. _145_)
      local _147_
      if (i <= 9) then
        _147_ = (i .. ":")
      else
        _147_ = ""
      end
      result = (result .. "%#" .. hl .. "# " .. _147_ .. " " .. "%#" .. icon_group .. "#" .. icon .. "%*%#" .. hl .. "# " .. name .. status .. " " .. buf_diag(buf) .. " %*")
    end
    return (result .. "%=%#TabLineFill# " .. workspace_diag() .. " ")
  end
  vim.o.tabline = "%!v:lua.Tabline.render()"
  vim.o.showtabline = 2
  _G.Tabline = Tabline
  for i = 1, 9 do
    local function _149_()
      return Tabline["goto"](i)
    end
    vim.keymap.set("n", ("<leader>" .. i), _149_, {desc = ("Go to buffer " .. i)})
  end
  local function tabline_update()
    local bufs = listed_bufs()
    if (#bufs > 1) then
      vim.o.showtabline = 2
    else
      vim.o.showtabline = 0
    end
    return nil
  end
  local function _151_()
    return tabline_update()
  end
  vim.api.nvim_create_autocmd({"BufAdd", "BufDelete", "BufEnter"}, {callback = _151_})
  local function _152_()
    if (vim.o.showtabline == 2) then
      vim.o.showtabline = 0
      return nil
    else
      return tabline_update()
    end
  end
  Tabline.toggle = _152_
  return vim.keymap.set("n", "<leader>tt", Tabline.toggle, {desc = "Toggle tabline"})
end
require("fnl.tabline")
package.preload["fnl.lsp"] = package.preload["fnl.lsp"] or function(...)
  local capabilities = require("blink.cmp").get_lsp_capabilities({textDocument = {foldingRange = {lineFoldingOnly = true, dynamicRegistration = false}}})
  local null_ls = require("null-ls")
  local problems = {{pattern = "\226\128\139", name = "ZERO WIDTH SPACE", replacement = ""}, {pattern = "\194\160", name = "NON-BREAKING SPACE", replacement = " "}, {pattern = "\239\187\191", name = "BYTE ORDER MARK", replacement = ""}, {pattern = "\226\128\141", name = "ZERO WIDTH JOINER", replacement = ""}, {pattern = "\226\128\142", name = "RIGHT-TO-LEFT MARK", replacement = ""}, {pattern = "\226\128\143", name = "LEFT-TO-RIGHT MARK", replacement = ""}}
  local no_problems
  local function _154_(params)
    local diagnostics = {}
    for i, line in ipairs(params.content) do
      for _, problem in ipairs(problems) do
        local col, end_col = line:find(problem.pattern, 1, true)
        if (col and end_col) then
          table.insert(diagnostics, {row = i, col = col, end_col = (end_col + 1), source = "no-problems", message = problem.name, severity = vim.diagnostic.severity.WARN})
        else
        end
      end
    end
    return diagnostics
  end
  no_problems = {method = null_ls.methods.DIAGNOSTICS, filetypes = {}, generator = {fn = _154_}}
  null_ls.setup({sources = {null_ls.builtins.formatting.fnlfmt, null_ls.builtins.formatting.stylua, null_ls.builtins.formatting.gofmt, null_ls.builtins.formatting.black, null_ls.builtins.formatting.isort, null_ls.builtins.formatting.nixfmt, null_ls.builtins.formatting.clang_format, null_ls.builtins.formatting.typstyle, null_ls.builtins.formatting.just, null_ls.builtins.formatting.gdformat, null_ls.builtins.formatting.dart_format, null_ls.builtins.formatting.prettierd, null_ls.builtins.formatting.cmake_format, null_ls.builtins.diagnostics.gdlint, null_ls.builtins.diagnostics.glslc.with({extra_args = {"--target-env=opengl"}}), null_ls.builtins.diagnostics.qmllint, null_ls.builtins.diagnostics.vale, null_ls.builtins.diagnostics.markdownlint, null_ls.builtins.diagnostics.checkmake, null_ls.builtins.diagnostics.cmake_lint, null_ls.builtins.diagnostics.statix, null_ls.builtins.diagnostics.deadnix, null_ls.builtins.diagnostics.fish, null_ls.builtins.hover.dictionary, null_ls.builtins.hover.printenv, null_ls.builtins.completion.spell, null_ls.builtins.code_actions.statix}})
  null_ls.register(no_problems)
  local function lsp_format_with_fallback(_opts)
    local opts = (_opts or {})
    local bufnr = (opts.bufnr or 0)
    local get_available = require("null-ls.sources").get_available
    local formatters = get_available(vim.bo[bufnr].filetype, null_ls.methods.FORMATTING)
    local null_ls_formats_3f = (nil ~= formatters[1])
    local function _156_(_241)
      return (not null_ls_formats_3f or (_241.name == "null-ls"))
    end
    return vim.lsp.buf.format({bufnr = bufnr, async = (opts.async or false), timeout_ms = (opts.timeout_ms or 1000), filter = _156_})
  end
  local function _157_()
    return lsp_format_with_fallback({timeout_ms = 500})
  end
  vim.api.nvim_create_autocmd("BufWritePre", {pattern = "*", callback = _157_})
  local function _158_()
    return lsp_format_with_fallback()
  end
  vim.keymap.set({"n", "v"}, "<leader>cf", _158_)
  vim.lsp.inlay_hint.enable()
  local noice = require("noice.lsp")
  local snacks = require("snacks")
  local function n(k, f, d)
    if d then
      return vim.keymap.set("n", k, f, {desc = ("LSP: " .. d)})
    else
      return vim.keymap.set("n", k, f)
    end
  end
  local function _160_()
    return snacks.picker.lsp_references()
  end
  n("gr", _160_, "[G]oto [R]eferences")
  local function _161_()
    return snacks.picker.lsp_implementations()
  end
  n("gI", _161_, "[G]oto [I]mplementation")
  local function _162_()
    return snacks.picker.lsp_symbols()
  end
  n("<leader>lds", _162_, "[D]ocument [S]ymbols")
  local function _163_()
    return snacks.picker.lsp_workspace_symbols()
  end
  n("<leader>ws", _163_, "[W]orkspace [S]ymbols")
  local function _164_()
    return vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
  end
  n("<leader>ei", _164_, "Toggle Inlay")
  n("K", noice.hover, "Hover Documentation")
  n("<leader>ltd", vim.lsp.buf.type_definition, "Type [D]efinition")
  n("<space>cl", vim.lsp.codelens.run, "[C]ode [L]ens")
  n("<F2>", vim.lsp.buf.rename, "[R]e[n]ame")
  n("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
  n("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
  n("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
  for _, k in ipairs({"asm_lsp", "ast_grep", "bashls", "cir_lsp_server", "clojure_lsp", "fennel_ls", "glsl_analyzer", "neocmake", "nixd", "html", "cssls", "fish_lsp", "omnisharp", "tinymist", "ocamllsp", "nushell", "denols", "jsonls", "pyrefly", "racket_langserver", "wasm_language_tools", "wgsl_analyzer", "zls", "matlab_ls", "gopls"}) do
    vim.lsp.enable(k)
  end
  vim.lsp.config("matlab_ls", {settings = {MATLAB = {indexWorkspace = true, installPath = vim.fn.expand("~/apps/matlab/installation/"), matlabConnectionTiming = "onStart", telemetry = true}}})
  return vim.lsp.config("nixd", {settings = {nixd = {nixpkgs = {expr = (vim.g.nix_nixd_nixpkgs or "import <nixpkgs> {}")}, options = {nixos = {expr = vim.g.nix_nixd_nixos_options}, ["home-manager"] = {expr = vim.g.nix_nixd_home_manager_options}}, formatting = {command = {"nixfmt"}}, diagnostic = {suppress = {"sema-escaping-with"}}}}})
end
require("fnl.lsp")
package.preload["fnl.dap"] = package.preload["fnl.dap"] or function(...)
  local function setup()
    local dap = require("dap")
    require("nvim-dap-virtual-text").setup()
    local frontend = require("dap-view")
    frontend.setup({winbar = {controls = {enabled = true}}})
    dap.listeners.before.attach.dapui_config = function()
      return frontend.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      return frontend.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      return frontend.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      return frontend.close()
    end
    dap.listeners.before.event_terminated["my-plugin"] = function(session, body)
      return vim.notify(("Session terminated" .. vim.inspect(session) .. vim.inspect(body)))
    end
    do
      local firefox_debug = os.getenv("VSCODE_FIREFOX_DEBUG")
      if firefox_debug then
        dap.adapters.firefox = {type = "executable", command = "node", args = {(firefox_debug .. "/dist/adapter.bundle.js")}}
      else
      end
    end
    dap.configurations.typescript = {{name = "Debug Firefox", type = "firefox", request = "launch", reAttach = true, url = "http://localhost:8080", webRoot = "${workspaceFolder}", firefoxExecutable = (os.getenv("BROWSER") or "firefox")}, {name = "Attach Firefox", type = "firefox", request = "attach", reAttach = true, url = "http://localhost:8080", webRoot = "${workspaceFolder}", firefoxExecutable = (os.getenv("BROWSER") or "firefox")}}
    dap.configurations.javascript = dap.configurations.typescript
    dap.configurations.javascriptreact = dap.configurations.typescript
    dap.configurations.typescriptreact = dap.configurations.typescript
    dap.adapters.gdb = {type = "executable", command = "gdb", args = {"--interpreter=dap", "--eval-command", "set print pretty on"}}
    dap.adapters["rust-gdb"] = {type = "executable", command = "rust-gdb", args = {"--interpreter=dap", "--eval-command", "set print pretty on"}}
    do
      local pick_2_auto
      local function _166_()
        return vim.fn.input("Path to executable: ", (vim.fn.getcwd() .. "/"), "file")
      end
      pick_2_auto = _166_
      local function _167_()
        local name_3_auto = vim.fn.input("Executable name (filter): ")
        return require("dap.utils").pick_process({filter = name_3_auto})
      end
      dap.configurations.c = {{args = {}, cwd = "${workspaceFolder}", name = "Launch", program = pick_2_auto, request = "launch", stopAtBeginningOfMainSubprogram = false, type = "gdb"}, {cwd = "${workspaceFolder}", name = "Select and attach to process", pid = _167_, program = pick_2_auto, request = "attach", type = "gdb"}, {cwd = "${workspaceFolder}", name = "Attach to gdbserver :1234", program = pick_2_auto, request = "attach", target = "localhost:1234", type = "gdb"}}
    end
    dap.configurations.cpp = dap.configurations.c
    dap.configurations.zig = dap.configurations.c
    do
      local pick_2_auto
      local function _168_()
        return vim.fn.input("Path to executable: ", (vim.fn.getcwd() .. "/"), "file")
      end
      pick_2_auto = _168_
      local function _169_()
        local name_3_auto = vim.fn.input("Executable name (filter): ")
        return require("dap.utils").pick_process({filter = name_3_auto})
      end
      dap.configurations.rust = {{args = {}, cwd = "${workspaceFolder}", name = "Launch", program = pick_2_auto, request = "launch", stopAtBeginningOfMainSubprogram = false, type = "rust-gdb"}, {cwd = "${workspaceFolder}", name = "Select and attach to process", pid = _169_, program = pick_2_auto, request = "attach", type = "rust-gdb"}, {cwd = "${workspaceFolder}", name = "Attach to gdbserver :1234", program = pick_2_auto, request = "attach", target = "localhost:1234", type = "rust-gdb"}}
    end
    local keymap_restore = {}
    dap.listeners.after.event_initialized.me = function()
      keymap_restore = {}
      for _, keymap in ipairs(vim.api.nvim_get_keymap("n")) do
        if (keymap.lhs == "K") then
          table.insert(keymap_restore, keymap)
        else
        end
      end
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        for _0, keymap in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
          if (keymap.lhs == "K") then
            table.insert(keymap_restore, keymap)
            vim.api.nvim_buf_del_keymap(buf, "n", "K")
          else
          end
        end
      end
      local function _172_()
        return frontend.hover()
      end
      return vim.keymap.set("n", "K", _172_, {silent = true})
    end
    dap.listeners.after.event_terminated.me = function()
      vim.keymap.del("n", "K")
      for _, keymap in ipairs(keymap_restore) do
        if (keymap.buffer == 0) then
          vim.fn.mapset(keymap)
        else
          if vim.api.nvim_buf_is_valid(keymap.buffer) then
            local function _173_()
              return vim.fn.mapset(keymap)
            end
            vim.api.nvim_buf_call(keymap.buffer, _173_)
          else
          end
        end
      end
      keymap_restore = {}
      return nil
    end
    vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, {desc = "Dap toggle_breakpoint"})
    vim.keymap.set("n", "<leader>dc", dap.continue, {desc = "Dap continue"})
    vim.keymap.set("n", "<leader>do", dap.step_over, {desc = "Dap step_over"})
    vim.keymap.set("n", "<leader>di", dap.step_into, {desc = "Dap step_into"})
    vim.keymap.set("n", "<leader>dt", dap.terminate, {desc = "Dap terminate"})
    vim.keymap.set("n", "<leader>dr", dap.repl.open, {desc = "Dap repl.open"})
    vim.keymap.set("n", "<M-c>", dap.continue, {desc = "Dap continue."})
    vim.keymap.set("n", "<M-o>", dap.step_over, {desc = "Dap step_over."})
    vim.keymap.set("n", "<M-i>", dap.step_into, {desc = "Dap step_into."})
    vim.keymap.set("n", "<M-t>", dap.terminate, {desc = "Dap terminate."})
    vim.keymap.set("n", "<M-r>", dap.repl.open, {desc = "Dap repl.open."})
    vim.keymap.set("n", "<leader>dui", frontend.open, {desc = "Dap ui open"})
    vim.keymap.set("n", "<leader>dux", frontend.close, {desc = "Dap ui close"})
    vim.keymap.set("n", "<leader>det", frontend.virtual_text_toggle, {desc = "Dap virt text toggle"})
    for name, sign in pairs({DapBreakpoint = {text = "\239\134\146", texthl = "DiagnosticError", linehl = "", numhl = ""}, DapBreakpointCondition = {text = "\239\129\153", texthl = "DiagnosticWarn", linehl = "", numhl = ""}, DapBreakpointRejected = {text = "\239\129\170", texthl = "DiagnosticError", linehl = "", numhl = ""}, DapLogPoint = {text = "\243\176\134\136", texthl = "DiagnosticInfo", linehl = "", numhl = ""}, DapStopped = {text = "\239\129\161", texthl = "DiagnosticWarn", linehl = "CursorLine", numhl = "DiagnosticWarn"}}) do
      vim.fn.sign_define(name, sign)
    end
    return nil
  end
  local function _176_()
    for _, p in ipairs({"nvim-dap-view", "nvim-dap-virtual-text", "nvim-dap-python"}) do
      vim.cmd.packadd(p)
    end
    return nil
  end
  return require("lz.n").load({"nvim-dap", keys = {"<leader>db", "<leader>dc", "<leader>do", "<leader>di", "<leader>dt", "<leader>dr", "<M-c>", "<M-o>", "<M-i>", "<M-t>", "<M-r>", "<leader>dui", "<leader>dux", "<leader>det"}, cmd = {"DapContinue", "DapNew", "DapToggleBreakpoint"}, before = _176_, after = setup})
end
require("fnl.dap")
local function _177_(opts)
  return vim.print(Fennel.eval(opts.args))
end
return vim.api.nvim_create_user_command("Fnl", _177_, {nargs = "+"})
