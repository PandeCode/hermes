vim.loader.enable()
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
  Utils.open_tmp_term = function(cmd)
    vim.cmd(("botright split | terminal " .. cmd))
    local bufnr = vim.api.nvim_win_get_buf(0)
    vim.api.nvim_set_option_value("buflisted", false, {buf = bufnr})
    vim.api.nvim_set_option_value("bufhidden", "wipe", {buf = bufnr})
    local h = math.floor((vim.o.lines / 4))
    vim.cmd(("resize " .. h))
    return vim.cmd("wincmd p")
  end
  Utils.mk_tmp_term = function(cmd)
    local function _12_()
      return Utils.open_tmp_term(cmd)
    end
    return _12_
  end
  Utils.bind_tmp_term = function(bind, cmd)
    local function _13_()
      return Utils.open_tmp_term(cmd)
    end
    return vim.keymap.set("n", bind, _13_)
  end
  return Utils.bind_tmp_term
end
require("fnl.utils")
package.preload["fnl.options"] = package.preload["fnl.options"] or function(...)
  vim.filetype.add({extension = {fnl = "fennel"}})
  local function _14_()
    vim.bo.commentstring = "// %s"
    return nil
  end
  vim.api.nvim_create_autocmd("Filetype", {pattern = {"wgsl", "glsl"}, callback = _14_})
  vim.g.no_plugin_maps = true
  for _, plugin in ipairs({"netrwPlugin", "netrw", "gzip", "zip", "zipPlugin", "tar", "tarPlugin", "getscript", "getscriptPlugin", "vimball", "vimballPlugin", "2html_plugin", "logipat", "rrhelper", "spellfile_plugin", "matchit"}) do
    vim.g[("loaded_" .. plugin)] = 1
  end
  for k, v in pairs({inccommand = "split", breakindent = true, number = true, relativenumber = true, termguicolors = true, cursorline = true, signcolumn = "yes", colorcolumn = "80", list = true, listchars = "tab:\226\134\146 ,lead:\194\183,trail:\194\183,nbsp:\226\144\163", pumblend = 20, winblend = 20, showmatch = true, scrolloff = 8, sidescrolloff = 8, laststatus = 3, expandtab = true, shiftwidth = 4, tabstop = 4, softtabstop = 4, smartindent = true, autoindent = true, smarttab = true, wrap = true, linebreak = true, formatoptions = "jcroqlnt", conceallevel = 1, virtualedit = "block", completeopt = "menu,menuone,noselect", hlsearch = true, incsearch = true, ignorecase = true, smartcase = true, gdefault = true, undofile = true, undodir = vim.fs.normalize("~/.cache/nvim/undodir"), hidden = true, confirm = true, autoread = true, fileencoding = "utf-8", encoding = "UTF-8", mouse = "a", updatetime = 100, timeoutlen = 500, ttimeoutlen = 10, history = 1000, cmdheight = 1, splitbelow = true, splitright = true, guifont = "FantasqueSansM Nerd Font:h14", guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175", visualbell = true, title = true, shortmess = "filnxtToOFIc", spell = true, spelllang = "en_us", synmaxcol = 240, ttyfast = true, redrawtime = 1000, wildignore = table.concat({"*.pyc", "*_build/*", "**/coverage/*", "**/Debug/*", "**/build/*", "**/node_modules/*", "**/android/*", "**/ios/*", "**/.git/*", "*.lock", "*.aux", "*.bbl", "*.bcf", "*.blg", "*.fdb_latexmk", "*.fls", "*.log", "*.pdf", "*.run.xml", "*.synctex.gz", "*.tex", "*.toc", "*.DS_Store", "*.class", "*.out"}, ","), wildmode = "longest:full,full", wildmenu = true, backspace = "indent,eol,start", showcmd = true, ruler = true, backup = false, showmode = false, swapfile = false, writebackup = false}) do
    vim.o[k] = v
  end
  return nil
end
require("fnl.options")
package.preload["fnl.keymaps"] = package.preload["fnl.keymaps"] or function(...)
  vim.g.mapleader = " "
  vim.g.maplocalleader = "\\"
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
  local silent = {silent = true}
  local noremap = {noremap = true}
  local noremap_expr = {noremap = true, expr = true}
  local noremap_silent = {silent = true, noremap = true}
  do
    n("<esc>", "<cmd>nohlsearch<cr>")
    local function _15_()
      vim.cmd.edit("%")
      return vim.treesitter.start()
    end
    n("<leader>fe", _15_)
    n("<leader>fs", "<cmd>w<cr>")
    n("<leader>fw", "<cmd>noautocmd w<cr>")
    n("<leader>li", "<cmd>lsp info<cr>", noremap_silent)
    n("<leader>lq", "<cmd>lsp stop<cr>", noremap_silent)
    n("<leader>lr", "<cmd>lsp restart<cr>", noremap_silent)
    n("<leader>ls", "<cmd>lsp start<cr>", noremap_silent)
    n("<leader>me", vim.cmd.messages, nil)
    n("<leader>bp", vim.cmd.bp, noremap_silent)
    n("<leader>bn", vim.cmd.bn, noremap_silent)
    n("<leader>bo", "<cmd>%bd|e#<cr>", noremap_silent)
    n("<A-d>", vim.cmd.bd, noremap_silent)
    n("<leader>c<leader>", "<cmd>normal gcc<cr>", noremap_silent)
    v("<leader>c<leader>", "gc", noremap_silent)
    n("<leader>`", "<cmd>e#<cr>", noremap_silent)
    n("<leader>gf", "<cmd>e <cfile><cr>")
    n("<leader><F2>", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/g<Left><Left>")
    local function _16_()
      if (vim.fn.mode() == "V") then
        return "^<C-v>I"
      else
        return "I"
      end
    end
    x("I", _16_, {expr = true})
    local function _18_()
      if (vim.fn.mode() == "V") then
        return "$<C-v>A"
      else
        return "A"
      end
    end
    x("A", _18_, {expr = true})
    n("Q", "")
    n("<Home>", "(col('.') == matchend(getline('.'), '^\\s*')+1 ? '0' : '^')", noremap_expr)
    n("<End>", "(col('.') == match(getline('.'), '\\s*$') ? '$' : 'g_')", noremap_expr)
    v("<End>", "(col('.') == match(getline('.'), '\\s*$') ? '$h' : 'g_')", noremap_expr)
    i("<Home>", "<C-o><Home>")
    i("<End> ", "<C-o><End>")
    n("gg", "gg0", noremap)
    a("G", "G<End>", noremap)
    a("Y", "y$", noremap)
    n("<leader>w", "<c-w>", noremap)
    n("<leader>w|", "<cmd>vsplit<cr>", noremap)
    n("<leader>w_", "<cmd>split<cr>", noremap)
    n("<leader>j", ":<c-u>put!=repeat([''],v:count)<bar>']+1<cr>", noremap_silent)
    n("<leader>k", ":<c-u>put =repeat([''],v:count)<bar>'[-1<cr>", noremap_silent)
    n("<c-c>", "\"+y\"", noremap)
    v("<c-c>", "\"+y\"", noremap)
    n("<c-v>", "\"+p\"", noremap)
    i("<c-v>", "<c-r>+", noremap)
    c("<c-v>", "<c-r>+", noremap)
    n("<c-x>", "<c-c>d")
    i("<c-x>", "<c-c>d")
    c("<c-x>", "<c-c>d")
    i("<c-r>", "<c-v>", noremap)
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
    local function _20_()
      if ((vim.g.showtabline == nil) or (vim.g.showtabline == 2)) then
        vim.g.showtabline = 0
        return vim.cmd("set showtabline=0")
      else
        vim.g.showtabline = 2
        return vim.cmd("set showtabline=2")
      end
    end
    n("<leader>tt", _20_, noremap)
  end
  return nil
end
require("fnl.keymaps")
package.preload["fnl.autocmds"] = package.preload["fnl.autocmds"] or function(...)
  local function _22_()
    local data = vim.fn.stdpath("data")
    local cwd = vim.fn.getcwd()
    cwd = (vim.fs.root(cwd, ".git") or cwd)
    local cwd_b64 = vim.base64.encode(cwd)
    local file = vim.fs.joinpath(data, "project_shada", cwd_b64)
    vim.fn.mkdir(vim.fs.dirname(file), "p")
    return file
  end
  vim.opt.shadafile = _22_()
  local function _23_()
    local line = vim.fn.line
    if ((line("'\"") > 0) and (line("'\"") <= line("$"))) then
      return vim.fn.execute("normal! g`\"")
    else
      return nil
    end
  end
  vim.api.nvim_create_autocmd("BufReadPost", {callback = _23_})
  local function _25_()
    return pcall(vim.treesitter.start)
  end
  vim.api.nvim_create_autocmd({"BufEnter", "BufWrite", "BufWritePost", "BufRead"}, {callback = _25_})
  vim.api.nvim_create_autocmd("TextYankPost", {callback = vim.hl.on_yank})
  local function _26_()
    return vim.fn.mkdir(vim.fn.expand("<afile>:p:h"), "p")
  end
  vim.api.nvim_create_autocmd("BufWritePre", {pattern = "*", callback = _26_})
  vim.opt.number = true
  vim.opt.relativenumber = true
  local function _27_()
    vim.opt.relativenumber = false
    return nil
  end
  vim.api.nvim_create_autocmd("InsertEnter", {pattern = "*", callback = _27_})
  local function _28_()
    vim.opt.relativenumber = true
    return nil
  end
  vim.api.nvim_create_autocmd("InsertLeave", {pattern = "*", callback = _28_})
  vim.cmd("\n\n\nif argc() > 1\n\tsilent blast \" load last buffer\n\tsilent bfirst \" switch back to the first\nendif\n\nif exists('+termguicolors')\n\tlet &t_8f=\"\\<Esc>[38;2;%lu;%lu;%lum\"\n\tlet &t_8b=\"\\<Esc>[48;2;%lu;%lu;%lum\"\n\tset termguicolors\nendif\n\nsyntax sync minlines=256\n\n\" Allow saving of files as sudo when I forgot to start vim using sudo.\ncnoremap w!! execute 'write !sudo tee % >/dev/null' <bar> edit!\n")
  local function _29_()
    local filename = vim.fn.expand("%")
    vim.cmd("!git add %")
    return vim.notify(("Git added '" .. filename .. "'"))
  end
  vim.api.nvim_create_user_command("Gitadd", _29_, {})
  local function _30_()
    local filename = vim.fn.expand("%")
    vim.cmd("!chmod +x %")
    return vim.notify(("Given execution rights to '" .. filename .. "'"))
  end
  vim.api.nvim_create_user_command("Chmodx", _30_, {})
  local function _31_()
    return vim.cmd("!rm -f %")
  end
  vim.api.nvim_create_user_command("Rmf", _31_, {})
  vim.cmd("\ncnoreabbrev W w\ncnoreabbrev Q q\ncnoreabbrev WQ wq\ncnoreabbrev Wq wq\ncnoreabbrev WQA wqa\ncnoreabbrev Wqa wqa\ncnoreabbrev QA qa\ncnoreabbrev Qa qa\ncnoreabbrev E e\ncnoreabbrev gitadd Gitadd\ncnoreabbrev chmodx Chmodx\ncnoreabbrev rmf Rmf\n")
  vim.diagnostic.config({virtual_text = true, virtual_lines = {current_line = true}, underline = true, update_in_insert = false})
  local og_virt_text = nil
  local og_virt_line = nil
  local function _32_()
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
  vim.api.nvim_create_autocmd({"CursorMoved", "DiagnosticChanged"}, {group = vim.api.nvim_create_augroup("diagnostic_only_virtlines", {}), callback = _32_})
  local function _38_()
    return pcall(vim.diagnostic.show)
  end
  vim.api.nvim_create_autocmd("ModeChanged", {group = vim.api.nvim_create_augroup("diagnostic_redraw", {}), callback = _38_})
  local function _39_()
    local name = vim.fn.expand("<afile>")
    if (name:match("fe") or name:match("^f$") or name:match("^e$")) then
      error(("Forbidden file name: " .. name))
      return vim.system({"rm", name})
    else
      return nil
    end
  end
  return vim.api.nvim_create_autocmd("BufWritePost", {pattern = "*", callback = _39_})
end
require("fnl.autocmds")
package.preload["fnl.plugins"] = package.preload["fnl.plugins"] or function(...)
  vim.cmd("packadd nvim.undotree")
  vim.cmd("packadd nvim.difftool")
  if (vim.g.nix_plugins == nil) then
  else
  end
  local plugins = {}
  vim.pack.add(plugins, {load = require("lz.n").load})
  require("oil").setup((nil or {}))
  require("dropbar").setup((nil or {}))
  vim.keymap.set("n", "-", "<cmd>Oil<CR>", {noremap = true, desc = "Open Parent Directory"})
  vim.keymap.set("n", "<leader>-", "<cmd>Oil .<CR>", {noremap = true, desc = "Open nvim root directory"})
  local function _42_()
    return pcall(vim.treesitter.start)
  end
  vim.api.nvim_create_autocmd({"BufEnter", "BufWrite", "BufWritePost"}, {callback = _42_})
  vim.bo.indentexpr = "v:lua.require('nvim-treesitter').indentexpr()"
  local ts_ctx = require("treesitter-context")
  ts_ctx.setup({enable = true, multiwindow = true})
  local function _43_()
    return ts_ctx.go_to_context(vim.v.count1)
  end
  vim.keymap.set("n", "[c", _43_, {silent = true})
  local ts_obj = require("nvim-treesitter-textobjects")
  ts_obj.setup({move = {set_jumps = true}})
  require("nvim-treesitter.config").setup(({highlight = {enable = true}, indent = {enable = true}, incremental_selection = {enable = true, keymaps = {init_selection = "<c-space>", node_incremental = "<c-space>", scope_incremental = "<c-s>", node_decremental = "<M-space>"}}, textobjects = {select = {enable = true, lookahead = true, keymaps = {aa = "@parameter.outer", ia = "@parameter.inner", af = "@function.outer", ["if"] = "@function.inner", ac = "@class.outer", ic = "@class.inner"}}, move = {enable = true, set_jumps = true, goto_next_start = {["]m"] = "@function.outer", ["]]"] = "@class.outer"}, goto_next_end = {["]M"] = "@function.outer", ["]["] = "@class.outer"}, goto_previous_start = {["[m"] = "@function.outer", ["[["] = "@class.outer"}, goto_previous_end = {["[M"] = "@function.outer", ["[]"] = "@class.outer"}}, swap = {enable = true, swap_next = {["<leader>a"] = "@parameter.inner"}, swap_previous = {["<leader>A"] = "@parameter.inner"}}}} or {}))
  require("snacks").setup({bigfile = {enabled = true}, dashboard = {enabled = false}, explorer = {enabled = true}, indent = {enabled = true}, input = {enabled = true}, picker = {enabled = true}, notifier = {enabled = true}, quickfile = {enabled = true}, scope = {enabled = true}, scroll = {enabled = true}, statuscolumn = {enabled = true}, words = {enabled = true}})
  local function sk(c)
    local function _44_()
      return Snacks.picker[c]()
    end
    return _44_
  end
  for _, v in ipairs({{"<leader>ff", sk("files"), "Find Files"}, {"<leader>fr", sk("grep"), "Grep"}, {"<leader>fm", sk("marks"), "Marks"}, {"<leader>fn", sk("man"), "Man"}, {"<leader><space>", sk("smart"), "Smart Find Files"}, {"<leader>fb", sk("buffers"), "Buffers"}, {"<leader>ch", sk("cliphist"), "cliphist"}, {"<leader>fll", sk("loclist"), "loclist"}, {"<leader>fq", sk("qflist"), "qflist"}, {"<leader>fld", sk("lsp_declarations"), "lsp_declarations"}, {"<leader>fle", sk("lsp_definitions"), "lsp_definitions"}, {"<leader>fli", sk("lsp_implementations"), "lsp_implementations"}, {"<leader>flr", sk("lsp_references"), "lsp_references"}, {"<leader>fls", sk("lsp_symbols"), "lsp_symbols"}, {"<leader>nh", Snacks.notifier.hide, "Notifier Hide"}, {"<leader>nh", Snacks.notifier.show_history, "Notifier Show"}}) do
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
  require("mini.clue").setup((nil or {}))
  local hipatterns = require("mini.hipatterns")
  local function _45_(_, _0, data)
    return MiniHipatterns.compute_hex_color_group(data.full_match:gsub("0x", "#"), "bg")
  end
  require("mini.hipatterns").setup(({highlighters = {fixme = {pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme"}, error = {pattern = "%f[%w]()ERROR()%f[%W]", group = "MiniHipatternsFixme"}, err = {pattern = "%f[%w]()ERR()%f[%W]", group = "MiniHipatternsFixme"}, bug = {pattern = "%f[%w]()BUG()%f[%W]", group = "MiniHipatternsFixme"}, hack = {pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack"}, warn = {pattern = "%f[%w]()WARN()%f[%W]", group = "MiniHipatternsHack"}, todo = {pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo"}, note = {pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote"}, info = {pattern = "%f[%w]()INFO()%f[%W]", group = "MiniHipatternsNote"}, base00 = {pattern = "base00", group = "GP_base00"}, base01 = {pattern = "base01", group = "GP_base01"}, base02 = {pattern = "base02", group = "GP_base02"}, base03 = {pattern = "base03", group = "GP_base03"}, base04 = {pattern = "base04", group = "GP_base04"}, base05 = {pattern = "base05", group = "GP_base05"}, base06 = {pattern = "base06", group = "GP_base06"}, base07 = {pattern = "base07", group = "GP_base07"}, base08 = {pattern = "base08", group = "GP_base08"}, base09 = {pattern = "base09", group = "GP_base09"}, base0A = {pattern = "base0A", group = "GP_base0A"}, base0B = {pattern = "base0B", group = "GP_base0B"}, base0C = {pattern = "base0C", group = "GP_base0C"}, base0D = {pattern = "base0D", group = "GP_base0D"}, base0E = {pattern = "base0E", group = "GP_base0E"}, base0F = {pattern = "base0F", group = "GP_base0F"}, hex_color = hipatterns.gen_highlighter.hex_color(), hex_num = {pattern = "0x%x%x%x%x%x%x%f[%X]", group = _45_, extmark_opts = {priority = 200}}}} or {}))
  local mini_s = require("mini.surround")
  local ts_input = mini_s.gen_spec.input.treesitter
  local function _46_()
    local n_star = MiniSurround.user_input("Number of * to find")
    local many_star = string.rep("%*", (tonumber(n_star) or 1))
    return {(many_star .. "().-()" .. many_star)}
  end
  local function _47_()
    local n_star = MiniSurround.user_input("Number of * to output")
    local many_star = string.rep("%*", (tonumber(n_star) or 1))
    return {left = many_star, right = many_star}
  end
  mini_s.setup({mappings = {add = "ys", delete = "ds", find = "", find_left = "", highlight = "", replace = "cs", update_n_lines = "", suffix_last = "", suffix_next = ""}, search_method = "cover_or_next", custom_surroundings = {f = {input = ts_input({outer = "@call.outer", inner = "@call.inner"})}, b = {input = ts_input({outer = "@block.out", inner = "@block.inner"})}, [")"] = {output = {left = "( ", right = " )"}}, ["*"] = {input = _46_, output = _47_}}})
  vim.keymap.del("x", "ys")
  vim.keymap.set("x", "S", ":<C-u>lua MiniSurround.add('visual')<CR>", {silent = true})
  vim.keymap.set("n", "yss", "ys_", {remap = true})
  local function _48_()
    MiniTrailspace.trim()
    return MiniTrailspace.trim_last_lines()
  end
  vim.api.nvim_create_autocmd({"BufWritePre"}, {pattern = "*", callback = _48_})
  require("blink.pairs").setup((nil or {}))
  require("blink.indent").setup((nil or {}))
  local function _49_(ctx)
    local kind_icon, _, _0 = MiniIcons.get("lsp", ctx.kind)
    return kind_icon
  end
  local function _50_(ctx)
    local _, hl, _0 = MiniIcons.get("lsp", ctx.kind)
    return hl
  end
  local function _51_(ctx)
    local _, hl, _0 = MiniIcons.get("lsp", ctx.kind)
    return hl
  end
  require("blink.cmp").setup(({signature = {enabled = true, window = {show_documentation = true}}, completion = {menu = {draw = {treesitter = {"lsp"}, columns = {{"kind_icon"}, {"label", "label_description", gap = 1}, {"kind"}}, components = {kind_icon = {text = _49_, highlight = _50_}, kind = {highlight = _51_}}}}, documentation = {auto_show = true}}} or {}))
  local function parinfer_on()
    pcall(vim.cmd, "ParinferOn")
    return vim.cmd.redrawstatus()
  end
  local function parinfer_off()
    pcall(vim.cmd, "ParinferOff")
    return vim.cmd.redrawstatus()
  end
  local function parinfer_toggle()
    if (vim.g.parinfer_enabled == 1) then
      return parinfer_off()
    else
      return parinfer_on()
    end
  end
  vim.keymap.set("n", "<leader>po", parinfer_on)
  vim.keymap.set("n", "<leader>pf", parinfer_off)
  vim.keymap.set("n", "<leader>pt", parinfer_toggle)
  local function _53_()
    if vim.tbl_contains({"racket", "lisp", "fennel"}, vim.bo.filetype) then
      return parinfer_on()
    else
      return parinfer_off()
    end
  end
  return vim.api.nvim_create_autocmd("FileType", {pattern = {"*"}, callback = _53_})
end
require("fnl.plugins")
package.preload["fnl.theme"] = package.preload["fnl.theme"] or function(...)
  local base16
  do
    local ok_3f, val = pcall(dofile, vim.fs.normalize("~/.config/stylix/style.lua"))
    if ok_3f then
      base16 = val
    else
      base16 = {base00 = "#1a1b26", base01 = "#16161e", base02 = "#2f3549", base03 = "#444b6a", base04 = "#787c99", base05 = "#a9b1d6", base06 = "#cbccd1", base07 = "#d5d6db", base08 = "#c0caf5", base09 = "#a9b1d6", base0A = "#0db9d7", base0B = "#9ece6a", base0C = "#b4f9f8", base0D = "#2ac3de", base0E = "#bb9af7", base0F = "#f7768e"}
    end
  end
  require("mini.base16").setup({use_cterm = true, palette = base16})
  vim.cmd(("hi LineNr guifg=" .. base16.base0E .. "\n" .. "hi LspInlayHint guifg=" .. base16.base04 .. "\n"))
  local IsTransparent = false
  local function set_hl(gp, opt)
    return vim.api.nvim_set_hl(0, gp, opt)
  end
  local function is_dark(_hex)
    local hex = _hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    local brightness = ((0.2126 * r) + (0.7152 * g) + (0.0722 * b))
    return (brightness < 128)
  end
  for group, color in pairs(base16) do
    local fg_color
    if is_dark(color) then
      fg_color = "#ffffff"
    else
      fg_color = "#000000"
    end
    vim.cmd(string.format("highlight GP_%s guifg=%s guibg=%s gui=NONE", group, fg_color, color))
  end
  local IsTransparent0 = true
  local function set_hl0(gp, opt)
    return vim.api.nvim_set_hl(0, gp, opt)
  end
  local function ToggleBackground()
    local palette = MiniBase16.config.palette
    if IsTransparent0 then
      set_hl0("Normal", {fg = palette.base05, bg = palette.base00})
      set_hl0("LineNr", {fg = palette.base03, bg = palette.base00})
      set_hl0("SignColumn", {fg = palette.base03, bg = palette.base00})
      set_hl0("NonText", {fg = palette.base02, bg = palette.base00})
      IsTransparent0 = false
      return nil
    else
      set_hl0("Normal", {bg = "NONE"})
      set_hl0("LineNr", {fg = palette.base03, bg = "NONE"})
      set_hl0("SignColumn", {fg = palette.base03, bg = "NONE"})
      set_hl0("NonText", {fg = palette.base02, bg = "NONE"})
      IsTransparent0 = true
      return nil
    end
  end
  vim.keymap.set("n", "<LEADER>bt", ToggleBackground, {noremap = true, silent = true})
  return nil
end
require("fnl.theme")
package.preload["fnl.statusline"] = package.preload["fnl.statusline"] or function(...)
  Statusline = {}
  local function sbcl_running_3f()
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
  vim.api.nvim_set_hl(0, "ParinferOn", {fg = MiniBase16.config.palette.base0B, bold = true})
  vim.api.nvim_set_hl(0, "ParinferOff", {fg = MiniBase16.config.palette.base03})
  local function get_attached_clients()
    local buf_clients = vim.lsp.get_clients({bufnr = 0})
    if (#buf_clients == 0) then
      return "No client active"
    else
      local buf_ft = vim.bo.filetype
      local buf_client_names = {}
      for _, client in pairs(buf_clients) do
        table.insert(buf_client_names, client.name)
      end
      do
        local ok_3f, null_ls = pcall(require, "null-ls")
        if ok_3f then
          for _, source in ipairs(null_ls.get_sources()) do
            if source._validated then
              for ft_name, ft_active in pairs(source.filetypes) do
                if ((ft_name == buf_ft) and ft_active) then
                  table.insert(buf_client_names, source.name)
                else
                end
              end
            else
            end
          end
        else
        end
      end
      if (("lisp" == buf_ft) and sbcl_running_3f()) then
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
    local _65_
    if (count.errors ~= 0) then
      _65_ = ("%#" .. "\239\129\151 " .. "#" .. tostring(count.errors) .. "%*")
    else
      _65_ = ""
    end
    local _67_
    if (count.warnings ~= 0) then
      _67_ = ("%#" .. "\239\129\177 " .. "#" .. tostring(count.warnings) .. "%*")
    else
      _67_ = ""
    end
    local _69_
    if (count.hints ~= 0) then
      _69_ = ("%#" .. "\239\129\154 " .. "#" .. tostring(count.hints) .. "%*")
    else
      _69_ = ""
    end
    local _71_
    if (count.info ~= 0) then
      _71_ = ("%#" .. "\239\129\153 " .. "#" .. tostring(count.info) .. "%*")
    else
      _71_ = ""
    end
    return (_65_ .. _67_ .. _69_ .. _71_ .. "%#Normal#")
  end
  local function git()
    local d = vim.b.gitsigns_status_dict
    if d then
      local _73_
      if (d.added and (d.added > 0)) then
        _73_ = ("%#" .. "GitSignsAdd" .. "#" .. tostring(("+ " .. d.added .. " ")) .. "%*")
      else
        _73_ = ""
      end
      local _75_
      if (d.changed and (d.changed > 0)) then
        _75_ = ("%#" .. "GitSignsChange" .. "#" .. tostring(("~ " .. d.changed .. " ")) .. "%*")
      else
        _75_ = ""
      end
      local _77_
      if (d.removed and (d.removed > 0)) then
        _77_ = ("%#" .. "GitSignsDelete" .. "#" .. tostring(("- " .. d.removed .. " ")) .. "%*")
      else
        _77_ = ""
      end
      return (("%#" .. "GitSignsAdd" .. "#" .. tostring((" \238\156\165 " .. d.head)) .. "%*") .. " " .. _73_ .. _75_ .. _77_)
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
  local function mode()
    local modes = {n = {"(\227\131\187_\227\131\187)", "base0D", "base00"}, i = {"(\227\129\163\226\128\162\204\128\207\137\226\128\162\204\129)\227\129\163", "base0B", "base00"}, v = {"(\225\151\146\225\151\168\225\151\149)", "base0E", "base00"}, V = {"(\225\151\146\225\151\168\225\151\149)\226\148\129", "base0E", "base00"}, ["\22"] = {"(\225\151\146\225\151\168\225\151\149)\226\150\136", "base0E", "base00"}, c = {"(\224\184\135 \226\128\162\204\128_\226\128\162\204\129)\224\184\135", "base0A", "base00"}, R = {"(\235\136\136_\235\136\136)", "base08", "base00"}}
    local m = vim.fn.mode()
    local p = MiniBase16.config.palette
    local _let_82_ = (modes[m] or {"?", "base05", "base00"})
    local text = _let_82_[1]
    local fg = _let_82_[2]
    local bg = _let_82_[3]
    vim.api.nvim_set_hl(0, "StatusLineMode", {fg = p[fg], bg = p[bg], bold = true})
    return ("%#StatusLineMode#" .. text .. "%*")
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
      local _86_
      do
        local pv_87_, pv_88_ = MiniIcons.get("os", "nixos")
        local icon_2_auto,hl_3_auto = pv_87_, pv_88_
        local _89_
        if hl_3_auto then
          _89_ = ("%#" .. hl_3_auto .. "#")
        else
          _89_ = ""
        end
        _86_ = (_89_ .. (icon_2_auto or "") .. "%*")
      end
      return (_86_ .. ("%#" .. "Comment" .. "#" .. tostring(env) .. "%*"))
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
    local _92_
    if (dir == ".") then
      _92_ = ""
    else
      _92_ = (dir .. "/")
    end
    local _94_
    if hl then
      _94_ = ("%#" .. hl .. "#")
    else
      _94_ = ""
    end
    local _96_
    if vim.bo.modified then
      _96_ = ("%#" .. "WarningMsg" .. "#" .. tostring("\226\151\143") .. "%*")
    else
      _96_ = ""
    end
    local _98_
    if vim.bo.readonly then
      _98_ = ("%#" .. "DiagnosticError" .. "#" .. tostring("\240\159\148\146") .. "%*")
    else
      _98_ = ""
    end
    return ("%#Comment#" .. _92_ .. "%*" .. (_94_ .. ((icon .. " " .. name) or "") .. "%*") .. " " .. _96_ .. _98_)
  end
  Statusline.active = function()
    local _100_
    do
      local pv_101_, pv_102_ = MiniIcons.get("file", (vim.fn.expand("%") or "default"))
      local icon_2_auto,hl_3_auto = pv_101_, pv_102_
      local _103_
      if hl_3_auto then
        _103_ = ("%#" .. hl_3_auto .. "#")
      else
        _103_ = ""
      end
      _100_ = (_103_ .. (icon_2_auto or "") .. "%*")
    end
    return (mode() .. " " .. recording() .. " " .. git() .. " " .. filename() .. " " .. lsp() .. "%=" .. get_attached_clients() .. "%=" .. searchcount() .. " " .. fun() .. " " .. nix_shell() .. " " .. _100_ .. " " .. "%{&filetype != '' ? &filetype : 'text'} " .. " " .. wordcount() .. " " .. "[%P %l:%c]")
  end
  Statusline.inactive = function()
    return "%#Comment# %t%*"
  end
  local group = vim.api.nvim_create_augroup("Statusline", {clear = true})
  local function _105_()
    vim.opt_local.statusline = "%!v:lua.Statusline.active()"
    return nil
  end
  vim.api.nvim_create_autocmd({"WinEnter", "BufEnter"}, {group = group, callback = _105_})
  local function _106_()
    vim.opt_local.statusline = "%!v:lua.Statusline.inactive()"
    return nil
  end
  vim.api.nvim_create_autocmd({"WinLeave", "BufLeave"}, {group = group, callback = _106_})
  local function _107_()
    return vim.cmd.redrawstatus()
  end
  return vim.defer_fn(_107_, 1000)
end
require("fnl.statusline")
package.preload["fnl.tabline"] = package.preload["fnl.tabline"] or function(...)
  local function _108_()
    return vim.cmd.redrawtabline()
  end
  vim.api.nvim_create_autocmd({"TermRequest", "ModeChanged"}, {desc = "Refresh tabline", callback = _108_})
  Tabline = {}
  do
    local p = MiniBase16.config.palette
    vim.api.nvim_set_hl(0, "TabActive", {fg = p.base00, bg = p.base0D, bold = true})
    vim.api.nvim_set_hl(0, "TabInactive", {fg = p.base03, bg = p.base01})
    vim.api.nvim_set_hl(0, "TabModified", {fg = p.base08, bg = p.base01})
    vim.api.nvim_set_hl(0, "TabLocked", {fg = p.base09, bg = p.base01})
  end
  local function listed_bufs()
    local function _109_(b)
      return (vim.api.nvim_buf_is_valid(b) and (1 == vim.fn.buflisted(b)) and (vim.api.nvim_buf_get_name(b) ~= ""))
    end
    return vim.tbl_filter(_109_, vim.api.nvim_list_bufs())
  end
  local function buf_diag(buf)
    local e = #vim.diagnostic.get(buf, {severity = vim.diagnostic.severity.ERROR})
    local w = #vim.diagnostic.get(buf, {severity = vim.diagnostic.severity.WARN})
    local _110_
    if (e > 0) then
      _110_ = ("%#DiagnosticSignError# " .. e .. "%*")
    else
      _110_ = ""
    end
    local _112_
    if (w > 0) then
      _112_ = ("%#DiagnosticSignWarn# " .. w .. "%*")
    else
      _112_ = ""
    end
    return (_110_ .. _112_)
  end
  local function workspace_diag()
    local e = #vim.diagnostic.get(nil, {severity = vim.diagnostic.severity.ERROR})
    local w = #vim.diagnostic.get(nil, {severity = vim.diagnostic.severity.WARN})
    local h = #vim.diagnostic.get(nil, {severity = vim.diagnostic.severity.HINT})
    local i = #vim.diagnostic.get(nil, {severity = vim.diagnostic.severity.INFO})
    local _114_
    if (e > 0) then
      _114_ = ("%#DiagnosticSignError# " .. e .. "%*")
    else
      _114_ = ""
    end
    local _116_
    if (w > 0) then
      _116_ = ("%#DiagnosticSignWarn# " .. w .. "%*")
    else
      _116_ = ""
    end
    local _118_
    if (h > 0) then
      _118_ = ("%#DiagnosticSignHint# " .. h .. "%*")
    else
      _118_ = ""
    end
    local _120_
    if (i > 0) then
      _120_ = ("%#DiagnosticSignInfo# " .. i .. "%*")
    else
      _120_ = ""
    end
    return (_114_ .. _116_ .. _118_ .. _120_)
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
      local icon, hl = MiniIcons.get("file", name)
      local modified = (1 == vim.fn.getbufvar(buf, "&modified"))
      local readonly = (1 == vim.fn.getbufvar(buf, "&readonly"))
      local nowrite = not vim.bo.modifiable
      local locked = (readonly or nowrite)
      local active = (buf == current)
      local hl0
      if active then
        hl0 = "TabActive"
      elseif locked then
        hl0 = "TabLocked"
      elseif modified then
        hl0 = "TabModified"
      else
        hl0 = "TabInactive"
      end
      local status
      if locked then
        status = " \243\176\140\190"
      elseif modified then
        status = " \226\151\143"
      else
        status = " "
      end
      local _125_
      if (i <= 9) then
        _125_ = (i .. ":")
      else
        _125_ = ""
      end
      result = (("%#" .. hl0 .. "#" .. tostring(icon) .. "%*") .. result .. "%#" .. hl0 .. "# " .. _125_ .. " " .. name .. status .. "%*" .. buf_diag(buf))
    end
    return (result .. "%=%#TabLineFill# " .. workspace_diag() .. " ")
  end
  vim.o.tabline = "%!v:lua.Tabline.render()"
  vim.o.showtabline = 2
  _G.Tabline = Tabline
  for i = 1, 9 do
    local function _127_()
      return Tabline["goto"](i)
    end
    vim.keymap.set("n", ("<leader>" .. i), _127_, {desc = ("Go to buffer " .. i)})
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
  local function _129_()
    return tabline_update()
  end
  vim.api.nvim_create_autocmd({"BufAdd", "BufDelete", "BufEnter"}, {callback = _129_})
  local function _130_()
    if (vim.o.showtabline == 2) then
      vim.o.showtabline = 0
      return nil
    else
      return tabline_update()
    end
  end
  return vim.keymap.set("n", "<leader>tt", _130_, {desc = "Toggle tabline"})
end
require("fnl.tabline")
package.preload["fnl.statuscol"] = package.preload["fnl.statuscol"] or function(...)
end
require("fnl.statuscol")
package.preload["fnl.lsp"] = package.preload["fnl.lsp"] or function(...)
  local capabilities = require("blink.cmp").get_lsp_capabilities({textDocument = {foldingRange = {lineFoldingOnly = true, dynamicRegistration = false}}})
  local null_ls = require("null-ls")
  local problems = {{pattern = "\226\128\139", name = "ZERO WIDTH SPACE", replacement = ""}, {pattern = "\194\160", name = "NON-BREAKING SPACE", replacement = " "}, {pattern = "\239\187\191", name = "BYTE ORDER MARK", replacement = ""}, {pattern = "\226\128\141", name = "ZERO WIDTH JOINER", replacement = ""}, {pattern = "\226\128\142", name = "RIGHT-TO-LEFT MARK", replacement = ""}, {pattern = "\226\128\143", name = "LEFT-TO-RIGHT MARK", replacement = ""}}
  local no_problems
  local function _132_(params)
    local diagnostics = {}
    for i, line in ipairs(params.content) do
      for _, problem in ipairs(problems) do
        local _local_133_ = line:find(problem.pattern)
        local col = _local_133_[1]
        local end_col = _local_133_[2]
        if (col and end_col) then
          table.insert(diagnostics, {row = i, col = col, end_col = (end_col + 1), source = "no-problems", message = problem.name, severity = vim.diagnostic.severity.WARN})
        else
        end
      end
    end
    return diagnostics
  end
  no_problems = {method = null_ls.methods.DIAGNOSTICS, filetypes = {"*"}, generator = {fn = _132_}}
  null_ls.setup({sources = {null_ls.builtins.formatting.fnlfmt, null_ls.builtins.formatting.stylua, null_ls.builtins.formatting.gofmt, null_ls.builtins.formatting.black, null_ls.builtins.formatting.isort, null_ls.builtins.formatting.alejandra, null_ls.builtins.formatting.nixfmt, null_ls.builtins.formatting.clang_format, null_ls.builtins.formatting.typstyle, null_ls.builtins.formatting.just, null_ls.builtins.formatting.gdformat, null_ls.builtins.formatting.dart_format, null_ls.builtins.formatting.prettierd, null_ls.builtins.formatting.cmake_format, null_ls.builtins.diagnostics.gdlint, null_ls.builtins.diagnostics.glslc.with({extra_args = {"--target-env=opengl"}}), null_ls.builtins.diagnostics.qmllint, null_ls.builtins.diagnostics.vale, null_ls.builtins.diagnostics.markdownlint, null_ls.builtins.diagnostics.checkmake, null_ls.builtins.diagnostics.cmake_lint, null_ls.builtins.diagnostics.statix, null_ls.builtins.diagnostics.deadnix, null_ls.builtins.diagnostics.fish, null_ls.builtins.hover.dictionary, null_ls.builtins.hover.printenv, null_ls.builtins.completion.spell, null_ls.builtins.code_actions.statix}})
  null_ls.register(no_problems)
  local function lsp_format_with_fallback(_opts)
    local opts = (_opts or {})
    return vim.lsp.buf.format({bufnr = (opts.bufnr or 0), async = (opts.async or false), timeout_ms = (opts.timeout_ms or 1000)})
  end
  local function _135_()
    return lsp_format_with_fallback({timeout_ms = 500})
  end
  vim.api.nvim_create_autocmd("BufWritePre", {pattern = "*", callback = _135_})
  local function _136_()
    return lsp_format_with_fallback()
  end
  vim.keymap.set({"n", "v"}, "<leader>cf", _136_)
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
  local function _138_()
    return snacks.picker.lsp_references()
  end
  n("gr", _138_, "[G]oto [R]eferences")
  local function _139_()
    return snacks.picker.lsp_implementations()
  end
  n("gI", _139_, "[G]oto [I]mplementation")
  local function _140_()
    return snacks.picker.lsp_symbols()
  end
  n("<leader>lds", _140_, "[D]ocument [S]ymbols")
  local function _141_()
    return snacks.picker.lsp_workspace_symbols()
  end
  n("<leader>ws", _141_, "[W]orkspace [S]ymbols")
  local function _142_()
    return vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
  end
  n("<leader>ei", _142_, "Toggle Inlay")
  n("K", noice.hover, "Hover Documentation")
  n("<leader>ltd", vim.lsp.buf.type_definition, "Type [D]efinition")
  n("<space>cl", vim.lsp.codelens.run, "[C]ode [L]ens")
  n("<F2>", vim.lsp.buf.rename, "[R]e[n]ame")
  n("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
  n("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
  n("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
  for _, k in ipairs({"emmylua_ls", "asm_lsp", "ast_grep", "bashls", "cir_lsp_server", "clojure_lsp", "neocmakelsp", "fennel_ls", "glsl_analyzer", "neocmake", "nixd", "html", "cssls", "fish_lsp", "omnisharp", "tinymist", "ocamllsp", "nushell", "denols", "jsonls", "pyright", "racket_langserver", "wasm_language_tools", "wgsl_analyzer", "zls", "matlab_ls", "gopls"}) do
    vim.lsp.enable(k)
  end
  vim.lsp.config("matlab_ls", {settings = {MATLAB = {indexWorkspace = true, installPath = vim.fn.expand("~/apps/matlab/installation/"), matlabConnectionTiming = "onStart", telemetry = true}}})
  return vim.lsp.config("nixd", {settings = {nixd = {nixpkgs = {expr = (vim.g.nix_nixd_nixpkgs or "import <nixpkgs> {}")}, options = {nixos = {expr = vim.g.nix_nixd_nixos_options}, ["home-manager"] = {expr = vim.g.nix_nixd_home_manager_options}}, formatting = {command = {"nixfmt"}}, diagnostic = {suppress = {"sema-escaping-with"}}}}})
end
require("fnl.lsp")
package.preload["fnl.dap"] = package.preload["fnl.dap"] or function(...)
  local dap = require("dap")
  require("nvim-dap-virtual-text").setup()
  local frontend = require("dap-view")
  frontend.setup()
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
  vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint)
  vim.keymap.set("n", "<leader>dc", dap.continue)
  vim.keymap.set("n", "<leader>do", dap.step_over)
  vim.keymap.set("n", "<leader>di", dap.step_into)
  vim.keymap.set("n", "<leader>di", dap.terminate)
  vim.keymap.set("n", "<leader>dr", dap.repl.open)
  dap.listeners.before.event_terminated["my-plugin"] = function(session, body)
    return vim.notify(("Session terminated" .. vim.inspect(session) .. vim.inspect(body)))
  end
  dap.adapters.gdb = {type = "executable", command = "gdb", args = {"--interpreter=dap", "--eval-command", "set print pretty on"}}
  dap.adapters["rust-gdb"] = {type = "executable", command = "rust-gdb", args = {"--interpreter=dap", "--eval-command", "set print pretty on"}}
  do
    local pick_2_auto
    local function _143_()
      return vim.fn.input("Path to executable: ", (vim.fn.getcwd() .. "/"), "file")
    end
    pick_2_auto = _143_
    local function _144_()
      local name_3_auto = vim.fn.input("Executable name (filter): ")
      return require("dap.utils").pick_process({filter = name_3_auto})
    end
    dap.configurations.c = {{args = {}, cwd = "${workspaceFolder}", name = "Launch", program = pick_2_auto, request = "launch", stopAtBeginningOfMainSubprogram = false, type = "gdb"}, {cwd = "${workspaceFolder}", name = "Select and attach to process", pid = _144_, program = pick_2_auto, request = "attach", type = "gdb"}, {cwd = "${workspaceFolder}", name = "Attach to gdbserver :1234", program = pick_2_auto, request = "attach", target = "localhost:1234", type = "gdb"}}
  end
  dap.configurations.cpp = dap.configurations.c
  dap.configurations.zig = dap.configurations.c
  do
    local pick_2_auto
    local function _145_()
      return vim.fn.input("Path to executable: ", (vim.fn.getcwd() .. "/"), "file")
    end
    pick_2_auto = _145_
    local function _146_()
      local name_3_auto = vim.fn.input("Executable name (filter): ")
      return require("dap.utils").pick_process({filter = name_3_auto})
    end
    dap.configurations.rust = {{args = {}, cwd = "${workspaceFolder}", name = "Launch", program = pick_2_auto, request = "launch", stopAtBeginningOfMainSubprogram = false, type = "rust-gdb"}, {cwd = "${workspaceFolder}", name = "Select and attach to process", pid = _146_, program = pick_2_auto, request = "attach", type = "rust-gdb"}, {cwd = "${workspaceFolder}", name = "Attach to gdbserver :1234", program = pick_2_auto, request = "attach", target = "localhost:1234", type = "rust-gdb"}}
  end
  return nil
end
return require("fnl.dap")
