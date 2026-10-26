vim.loader.enable()
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
Fennel = nil
do
  local ok_3f, fennel = pcall(require, "fennel")
  if ok_3f then
    fennel.install()
    Fennel = fennel
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
  local function cmd_for(name)
    return (vim.g[name] or vim.b[name])
  end
  Utils.set_qf = function(title, lines, efm)
    vim.fn.setqflist({}, " ", {title = title, lines = lines, efm = efm})
    local _17_
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for _, e in ipairs(vim.fn.getqflist()) do
        local val_28_
        do
          if (e.bufnr == 0) then
            e.valid = 0
          else
          end
          val_28_ = e
        end
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      _17_ = tbl_26_
    end
    return vim.fn.setqflist({}, "r", {items = _17_})
  end
  Utils.build = function(on_ok, cmd_3f)
    local cmd = (cmd_3f or cmd_for("build_cmd"))
    local efm = vim.api.nvim_get_option_value("errorformat", {})
    if not cmd then
      if on_ok then
        return on_ok()
      else
        return nil
      end
    else
      vim.cmd("silent! wall")
      vim.notify(cmd)
      local function _21_(out)
        local output = (out.stdout .. out.stderr)
        Utils.set_qf(cmd, vim.split(output, "\n"), efm)
        if (out.code == 0) then
          vim.cmd.cclose()
          if on_ok then
            return on_ok()
          else
            return vim.notify((cmd .. " ok"))
          end
        elseif (0 == #vim.fn.getqflist()) then
          return vim.notify(output, vim.log.levels.ERROR)
        else
          return vim.cmd("botright copen")
        end
      end
      return vim.system({"sh", "-c", vim.fn.expandcmd(cmd)}, {text = true}, vim.schedule_wrap(_21_))
    end
  end
  local function trace_to_qf(term, title, efm)
    if vim.api.nvim_buf_is_valid(term) then
      Utils.set_qf(title, vim.api.nvim_buf_get_lines(term, 0, -1, false), efm)
      local _25_
      do
        local any = false
        for _, e in ipairs(vim.fn.getqflist()) do
          any = (any or (e.valid == 1))
        end
        _25_ = any
      end
      if _25_ then
        return vim.cmd("botright copen")
      else
        return nil
      end
    else
      return nil
    end
  end
  Utils.term_with_trace = function(cmd)
    local efm = vim.api.nvim_get_option_value("errorformat", {})
    local function _28_(term)
      local function _29_()
        if (0 ~= vim.v.event.status) then
          local function _30_()
            return trace_to_qf(term, cmd, efm)
          end
          return vim.schedule(_30_)
        else
          return nil
        end
      end
      return vim.api.nvim_create_autocmd("TermClose", {buffer = term, once = true, callback = _29_})
    end
    return Utils.open_tmp_term(cmd, _28_)
  end
  Utils.run = function()
    local function _32_()
      local cmd = cmd_for("run_cmd")
      if cmd then
        return Utils.term_with_trace(cmd)
      else
        return vim.notify("no run_cmd", vim.log.levels.WARN)
      end
    end
    return Utils.build(_32_)
  end
  Utils.test_at = {}
  Utils.test = function()
    local cmd = cmd_for("test_cmd")
    local find = Utils.test_at[vim.bo.filetype]
    local plan = ((find and find()) or {})
    local filter = cmd_for("test_filter")
    if plan.term then
      vim.cmd("silent! wall")
      return Utils.term_with_trace(plan.term)
    elseif not cmd then
      return vim.notify("no test_cmd", vim.log.levels.WARN)
    elseif (plan.name and filter) then
      return Utils.build(nil, (cmd .. " " .. filter .. (vim.fn.shellescape(plan.name):gsub("[%%#]", "\\%0"))))
    else
      return Utils.build(nil, cmd)
    end
  end
  local function _35_()
    return Utils.build()
  end
  vim.keymap.set("n", "<leader>mb", _35_)
  vim.keymap.set("n", "<leader>mr", Utils.run)
  vim.keymap.set("n", "<leader>mt", Utils.test)
  local function runner(cmd)
    local function _36_()
      vim.g.run_cmd = cmd
      return nil
    end
    return _36_
  end
  local function _37_()
    return def_ui({bind_nix = runner("nix-instantiate --show-trace --eval ./%"), bind_zig = runner("zig build run -freference-trace=10 -j$(nproc)"), bind_run = runner("make run"), bind_exe = runner("./%")})
  end
  return vim.keymap.set("n", "<leader>bb", _37_)
end
require("fnl.utils")
package.preload["fnl.options"] = package.preload["fnl.options"] or function(...)
  local function _38_()
    vim.bo.commentstring = "// %s"
    return nil
  end
  vim.api.nvim_create_autocmd("Filetype", {pattern = {"wgsl", "glsl"}, callback = _38_})
  vim.g.no_plugin_maps = true
  for _, plugin in ipairs({"netrwPlugin", "netrw", "gzip", "nvim_zip_plugin", "tar", "tarPlugin", "spellfile_plugin", "matchit"}) do
    vim.g[("loaded_" .. plugin)] = 1
  end
  for k, v in pairs({inccommand = "split", exrc = true, breakindent = true, number = true, relativenumber = true, termguicolors = true, cursorline = true, signcolumn = "yes", colorcolumn = "80", list = true, listchars = "tab:\226\134\146 ,lead:\194\183,trail:\194\183,nbsp:\226\144\163", pumblend = 20, winblend = 20, showmatch = true, scrolloff = 8, sidescrolloff = 8, laststatus = 3, expandtab = true, shiftwidth = 4, tabstop = 4, softtabstop = 4, smartindent = true, autoindent = true, smarttab = true, wrap = true, linebreak = true, formatoptions = "jcroqlnt", conceallevel = 1, virtualedit = "block", completeopt = "menu,menuone,noselect", hlsearch = true, incsearch = true, ignorecase = true, smartcase = true, gdefault = true, undofile = true, hidden = true, confirm = true, autoread = true, fileencoding = "utf-8", mouse = "a", updatetime = 100, timeoutlen = 500, ttimeoutlen = 10, history = 1000, cmdheight = 1, splitbelow = true, splitright = true, guifont = "FantasqueSansM Nerd Font:h14", guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175", visualbell = true, title = true, shortmess = "filnxtToOFIc", spell = true, spelllang = "en_us", synmaxcol = 240, redrawtime = 1000, wildignore = table.concat({"*.pyc", "*_build/*", "**/coverage/*", "**/Debug/*", "**/build/*", "**/node_modules/*", "**/.git/*", "*.aux", "*.bbl", "*.bcf", "*.blg", "*.fdb_latexmk", "*.fls", "*.run.xml", "*.synctex.gz", "*.toc", "*.DS_Store", "*.class", "*.out"}, ","), wildmode = "longest:full,full", wildmenu = true, backspace = "indent,eol,start", showcmd = true, ruler = true, backup = false, showmode = false, swapfile = false, writebackup = false}) do
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
  local function i(a_2_auto, b_3_auto, c_4_auto)
    return vim.keymap.set("i", a_2_auto, b_3_auto, c_4_auto)
  end
  local function x(a_2_auto, b_3_auto, c_4_auto)
    return vim.keymap.set("x", a_2_auto, b_3_auto, c_4_auto)
  end
  local function a(a_2_auto, b_3_auto, c_4_auto)
    return vim.keymap.set({"n", "x", "o"}, a_2_auto, b_3_auto, c_4_auto)
  end
  local noremap = {noremap = true}
  local noremap_expr = {noremap = true, expr = true}
  local noremap_silent = {silent = true, noremap = true}
  do
    n("<esc>", "<cmd>nohlsearch<cr>")
    local function _39_()
      vim.cmd.edit("%")
      return pcall(vim.treesitter.start)
    end
    n("<leader>fe", _39_)
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
    x("<leader>c<leader>", "gc", {remap = true, silent = true})
    n("<leader>`", "<cmd>e#<cr>", noremap_silent)
    n("<leader>gf", "<cmd>e <cfile><cr>")
    n("<leader><F2>", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/<Left>")
    local function _40_()
      if (vim.fn.mode() == "V") then
        return "^<C-v>I"
      else
        return "I"
      end
    end
    x("I", _40_, {expr = true})
    local function _42_()
      if (vim.fn.mode() == "V") then
        return "$<C-v>A"
      else
        return "A"
      end
    end
    x("A", _42_, {expr = true})
    n("<Home>", "(col('.') == matchend(getline('.'), '^\\s*')+1 ? '0' : '^')", noremap_expr)
    n("<End>", "(col('.') == match(getline('.'), '\\s*$') ? '$' : 'g_')", noremap_expr)
    x("<End>", "(col('.') == match(getline('.'), '\\s*$') ? '$h' : 'g_')", noremap_expr)
    n("gg", "gg0", noremap)
    a("G", "G<End>", noremap)
    n("<leader>w", "<c-w>", noremap)
    n("<leader>w|", "<cmd>vsplit<cr>", noremap)
    n("<leader>w_", "<cmd>split<cr>", noremap)
    n("<leader>j", ":<c-u>put!=repeat([''],v:count)<bar>']+1<cr>", noremap_silent)
    n("<leader>k", ":<c-u>put =repeat([''],v:count)<bar>'[-1<cr>", noremap_silent)
    n("<c-c>", "\"+y", noremap)
    x("<c-c>", "\"+y", noremap)
    n("<c-v>", "\"+p", noremap)
    i("<c-v>", "<c-r>+", noremap)
    c("<c-v>", "<c-r>+", noremap)
    n("<c-x>", "\"+dd", noremap)
    x("<c-x>", "\"+d", noremap)
    n("n", "nzzzv", noremap)
    n("N", "Nzzzv", noremap)
    n("J", "mzJ`z", noremap)
    i(",", ",<c-g>u", noremap)
    i(".", ".<c-g>u", noremap)
    i("!", "!<c-g>u", noremap)
    i("?", "?<c-g>u", noremap)
    n("<", "v<gv<ESC>", noremap)
    n(">", "v>gv<ESC>", noremap)
    x("<", "<gv", noremap)
    x(">", ">gv", noremap)
    x("`", "<ESC>`>a`<ESC>`<i`<ESC>", noremap)
    x("(", "<ESC>`>a)<ESC>`<i(<ESC>", noremap)
    x("'", "<ESC>`>a'<ESC>`<i'<ESC>", noremap)
    x("<c-{>", "<ESC>`>a}<ESC>`<i{<ESC>", noremap)
    x(")", "<ESC>`>a)<ESC>`<i(<ESC>", noremap)
    x("]", "<ESC>`>a]<ESC>`<i[<ESC>", noremap)
    x("<c-}>", "<ESC>`>a}<ESC>`<i{<ESC>", noremap)
    x("/", "<Esc>/\\%V")
    i("<c-f>", "<c-g>u<Esc>[s1z=gi<c-g>u", noremap)
  end
  return nil
end
require("fnl.keymaps")
package.preload["fnl.autocmds"] = package.preload["fnl.autocmds"] or function(...)
  local function _44_()
    local data = vim.fn.stdpath("data")
    local cwd = vim.fn.getcwd()
    cwd = (vim.fs.root(cwd, ".git") or cwd)
    local file = vim.fs.joinpath(data, "project_shada", vim.fn.sha256(cwd))
    vim.fn.mkdir(vim.fs.dirname(file), "p")
    return file
  end
  vim.opt.shadafile = _44_()
  local function _45_()
    local line = vim.fn.line
    if ((line("'\"") > 0) and (line("'\"") <= line("$"))) then
      vim.fn.execute("normal! g`\"")
    else
    end
    return nil
  end
  vim.api.nvim_create_autocmd("BufReadPost", {callback = _45_})
  local function _47_()
    return vim.hl.hl_op()
  end
  vim.api.nvim_create_autocmd("TextYankPost", {callback = _47_})
  local function _48_(args)
    if ((vim.bo[args.buf].buftype == "") and not args.match:find("://", 1, true)) then
      vim.fn.mkdir(vim.fn.fnamemodify(args.match, ":p:h"), "p")
    else
    end
    return nil
  end
  vim.api.nvim_create_autocmd("BufWritePre", {pattern = "*", callback = _48_})
  local function _50_()
    if vim.wo.relativenumber then
      vim.wo.relativenumber = false
      vim.w.rnu_insert = true
      return nil
    else
      return nil
    end
  end
  vim.api.nvim_create_autocmd("InsertEnter", {callback = _50_})
  local function _52_()
    if vim.w.rnu_insert then
      vim.wo.relativenumber = true
      vim.w.rnu_insert = nil
      return nil
    else
      return nil
    end
  end
  vim.api.nvim_create_autocmd("InsertLeave", {callback = _52_})
  local function _54_()
    if (vim.fn.argc() > 1) then
      vim.cmd("silent blast | silent bfirst")
      return nil
    else
      return nil
    end
  end
  vim.api.nvim_create_autocmd("VimEnter", {nested = true, callback = _54_})
  local function _56_()
    local filename = vim.fn.expand("%")
    vim.cmd("!git add %")
    return vim.notify(("Git added '" .. filename .. "'"))
  end
  vim.api.nvim_create_user_command("Gitadd", _56_, {})
  local function _57_()
    local filename = vim.fn.expand("%")
    vim.cmd("!chmod +x %")
    return vim.notify(("Given execution rights to '" .. filename .. "'"))
  end
  vim.api.nvim_create_user_command("Chmodx", _57_, {})
  local function _58_()
    return vim.cmd("!rm -f %")
  end
  vim.api.nvim_create_user_command("Rmf", _58_, {})
  for from, to in pairs({W = "w", Q = "q", WQ = "wq", Wq = "wq", WQA = "wqa", Wqa = "wqa", QA = "qa", Qa = "qa", E = "e", gitadd = "Gitadd", chmodx = "Chmodx", rmf = "Rmf", fnl = "Fnl"}) do
    local function _59_()
      if ((vim.fn.getcmdtype() == ":") and (vim.fn.getcmdline() == from)) then
        return to
      else
        return from
      end
    end
    vim.keymap.set("ca", from, _59_, {expr = true})
  end
  vim.diagnostic.config({virtual_text = true, virtual_lines = {current_line = true}, underline = true, update_in_insert = false})
  local og_virt_text = nil
  local function _61_()
    do
      local lines = vim.diagnostic.config().virtual_lines
      local lnum = (vim.api.nvim_win_get_cursor(0)[1] - 1)
      local hide_3f = ((type(lines) == "table") and lines.current_line and not vim.tbl_isempty(vim.diagnostic.get(0, {lnum = lnum})))
      if (hide_3f and (og_virt_text == nil)) then
        og_virt_text = vim.diagnostic.config().virtual_text
        vim.diagnostic.config({virtual_text = false})
      elseif (not hide_3f and (og_virt_text ~= nil)) then
        vim.diagnostic.config({virtual_text = og_virt_text})
        og_virt_text = nil
      else
      end
    end
    return nil
  end
  vim.api.nvim_create_autocmd({"CursorMoved", "DiagnosticChanged"}, {group = vim.api.nvim_create_augroup("diagnostic_only_virtlines", {}), callback = _61_})
  local function _63_(args)
    vim.b[args.buf]["typo_file"] = ((vim.fn.fnamemodify(args.match, ":p:h") == vim.fn.getcwd()) and (vim.fn.filereadable(args.match) == 0))
    return nil
  end
  vim.api.nvim_create_autocmd("BufWritePre", {pattern = {"f", "fe"}, callback = _63_})
  local function _64_(args)
    if vim.b[args.buf].typo_file then
      vim.fn.delete(args.match)
    else
    end
    return nil
  end
  vim.api.nvim_create_autocmd("BufWritePost", {pattern = {"f", "fe"}, callback = _64_})
  local function _66_(args)
    local pdf = vim.fn.fnamemodify(args.file, ":p")
    local typ = (vim.fn.fnamemodify(pdf, ":r") .. ".typ")
    if (1 == vim.fn.filereadable(typ)) then
      local function _67_()
        vim.cmd.edit(typ)
        if vim.api.nvim_buf_is_valid(args.buf) then
          return vim.api.nvim_buf_delete(args.buf, {force = true})
        else
          return nil
        end
      end
      vim.schedule(_67_)
    else
    end
    if ((0 == vim.fn.filereadable(typ)) and (1 == vim.fn.filereadable(pdf))) then
      local function _70_()
        vim.fn.jobstart({"zathura", pdf}, {detach = true})
        return vim.cmd("qa!")
      end
      vim.schedule(_70_)
    else
    end
    return nil
  end
  return vim.api.nvim_create_autocmd({"BufReadPre", "BufNewFile"}, {pattern = "*.pdf", callback = _66_})
end
require("fnl.autocmds")
package.preload["fnl.plugins"] = package.preload["fnl.plugins"] or function(...)
  vim.cmd("packadd nvim.undotree")
  vim.cmd("packadd nvim.difftool")
  require("oil").setup((nil or {}))
  vim.keymap.set("n", "-", "<cmd>Oil<CR>", {noremap = true, desc = "Open Parent Directory"})
  vim.keymap.set("n", "<leader>-", "<cmd>Oil .<CR>", {noremap = true, desc = "Open nvim root directory"})
  local function _72_(args)
    if pcall(vim.treesitter.start, args.buf) then
      vim.bo[args.buf]["indentexpr"] = "v:lua.require'nvim-treesitter'.indentexpr()"
      return nil
    else
      return nil
    end
  end
  vim.api.nvim_create_autocmd("FileType", {group = vim.api.nvim_create_augroup("treesitter_start", {}), callback = _72_})
  local ts_ctx = require("treesitter-context")
  ts_ctx.setup({enable = true, multiwindow = true})
  local function _74_()
    if vim.wo.diff then
      return vim.cmd(("normal! " .. vim.v.count1 .. "[c"))
    else
      return ts_ctx.go_to_context(vim.v.count1)
    end
  end
  vim.keymap.set("n", "[c", _74_, {silent = true})
  local ts_obj = require("nvim-treesitter-textobjects")
  ts_obj.setup({select = {lookahead = true}, move = {set_jumps = true}})
  local ts_select = require("nvim-treesitter-textobjects.select")
  local ts_move = require("nvim-treesitter-textobjects.move")
  local ts_swap = require("nvim-treesitter-textobjects.swap")
  for key, capture in pairs({aa = "@parameter.outer", ia = "@parameter.inner", af = "@function.outer", ["if"] = "@function.inner", ac = "@class.outer", ic = "@class.inner"}) do
    local function _76_()
      return ts_select.select_textobject(capture, "textobjects")
    end
    vim.keymap.set({"x", "o"}, key, _76_)
  end
  for key, _77_ in pairs({["]m"] = {"goto_next_start", "@function.outer"}, ["]]"] = {"goto_next_start", "@class.outer"}, ["]M"] = {"goto_next_end", "@function.outer"}, ["]["] = {"goto_next_end", "@class.outer"}, ["[m"] = {"goto_previous_start", "@function.outer"}, ["[["] = {"goto_previous_start", "@class.outer"}, ["[M"] = {"goto_previous_end", "@function.outer"}, ["[]"] = {"goto_previous_end", "@class.outer"}}) do
    local move = _77_[1]
    local capture = _77_[2]
    local function _78_()
      return ts_move[move](capture, "textobjects")
    end
    vim.keymap.set({"n", "x", "o"}, key, _78_)
  end
  local function _79_()
    return ts_swap.swap_next("@parameter.inner")
  end
  vim.keymap.set("n", "<leader>a", _79_)
  local function _80_()
    return ts_swap.swap_previous("@parameter.inner")
  end
  vim.keymap.set("n", "<leader>A", _80_)
  vim.keymap.set("n", "<c-space>", "van", {remap = true})
  vim.keymap.set("x", "<c-space>", "an", {remap = true})
  vim.keymap.set("x", "<M-space>", "in", {remap = true})
  require("snacks").setup({bigfile = {enabled = true}, dashboard = {enabled = false}, explorer = {enabled = true}, indent = {enabled = true}, input = {enabled = true}, picker = {enabled = true}, notifier = {enabled = true}, quickfile = {enabled = true}, scope = {enabled = true}, scroll = {enabled = true}, statuscolumn = {enabled = true}, words = {enabled = true}})
  local function sk(c)
    local function _81_()
      return Snacks.picker[c]()
    end
    return _81_
  end
  for _, v in ipairs({{"<leader>ff", sk("files"), "Find Files"}, {"<leader>fr", sk("grep"), "Grep"}, {"<leader>fm", sk("marks"), "Marks"}, {"<leader>fn", sk("man"), "Man"}, {"<leader><space>", sk("smart"), "Smart Find Files"}, {"<leader>fb", sk("buffers"), "Buffers"}, {"<leader>ch", sk("cliphist"), "cliphist"}, {"<leader>fll", sk("loclist"), "loclist"}, {"<leader>fq", sk("qflist"), "qflist"}, {"<leader>fld", sk("lsp_declarations"), "lsp_declarations"}, {"<leader>fle", sk("lsp_definitions"), "lsp_definitions"}, {"<leader>fli", sk("lsp_implementations"), "lsp_implementations"}, {"<leader>flr", sk("lsp_references"), "lsp_references"}, {"<leader>fls", sk("lsp_symbols"), "lsp_symbols"}, {"<leader>nh", Snacks.notifier.hide, "Notifier Hide"}, {"<leader>ns", Snacks.notifier.show_history, "Notifier Show"}}) do
    vim.keymap.set("n", v[1], v[2], {desc = v[3]})
  end
  require("noice").setup(({lsp = {override = {["vim.lsp.util.convert_input_to_markdown_lines"] = true, ["vim.lsp.util.stylize_markdown"] = true}, signature = {enabled = false}}, presets = {command_palette = true, long_message_to_split = true, lsp_doc_border = true, bottom_search = false, inc_rename = false}} or {}))
  require("mini.icons").setup((nil or {}))
  require("mini.cursorword").setup((nil or {}))
  require("mini.pairs").setup((nil or {}))
  require("mini.align").setup((nil or {}))
  require("mini.move").setup((nil or {}))
  require("mini.splitjoin").setup((nil or {}))
  require("mini.trailspace").setup((nil or {}))
  local miniclue = require("mini.clue")
  require("mini.clue").setup(({triggers = {{mode = {"n", "x"}, keys = "<leader>"}, {mode = {"n", "x"}, keys = "g"}, {mode = {"n", "x"}, keys = "z"}, {mode = {"n", "x"}, keys = "<c-w>"}, {mode = {"n", "x"}, keys = "'"}, {mode = {"n", "x"}, keys = "`"}, {mode = {"n", "x"}, keys = "\""}}, clues = {miniclue.gen_clues.marks(), miniclue.gen_clues.registers(), miniclue.gen_clues.windows(), miniclue.gen_clues.z(), miniclue.gen_clues.g()}} or {}))
  local hipatterns = require("mini.hipatterns")
  local function _82_(_, _0, data)
    return MiniHipatterns.compute_hex_color_group(data.full_match:gsub("0x", "#"), "bg")
  end
  require("mini.hipatterns").setup(({highlighters = {fixme = {pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme"}, error = {pattern = "%f[%w]()ERROR()%f[%W]", group = "MiniHipatternsFixme"}, err = {pattern = "%f[%w]()ERR()%f[%W]", group = "MiniHipatternsFixme"}, bug = {pattern = "%f[%w]()BUG()%f[%W]", group = "MiniHipatternsFixme"}, hack = {pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack"}, warn = {pattern = "%f[%w]()WARN()%f[%W]", group = "MiniHipatternsHack"}, todo = {pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo"}, note = {pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote"}, info = {pattern = "%f[%w]()INFO()%f[%W]", group = "MiniHipatternsNote"}, base00 = {pattern = "base00", group = "GP_base00"}, base01 = {pattern = "base01", group = "GP_base01"}, base02 = {pattern = "base02", group = "GP_base02"}, base03 = {pattern = "base03", group = "GP_base03"}, base04 = {pattern = "base04", group = "GP_base04"}, base05 = {pattern = "base05", group = "GP_base05"}, base06 = {pattern = "base06", group = "GP_base06"}, base07 = {pattern = "base07", group = "GP_base07"}, base08 = {pattern = "base08", group = "GP_base08"}, base09 = {pattern = "base09", group = "GP_base09"}, base0A = {pattern = "base0A", group = "GP_base0A"}, base0B = {pattern = "base0B", group = "GP_base0B"}, base0C = {pattern = "base0C", group = "GP_base0C"}, base0D = {pattern = "base0D", group = "GP_base0D"}, base0E = {pattern = "base0E", group = "GP_base0E"}, base0F = {pattern = "base0F", group = "GP_base0F"}, hex_color = hipatterns.gen_highlighter.hex_color(), hex_num = {pattern = "0x%x%x%x%x%x%x%f[%X]", group = _82_, extmark_opts = {priority = 200}}}} or {}))
  local mini_s = require("mini.surround")
  local ts_input = mini_s.gen_spec.input.treesitter
  local function _83_()
    local n_star = MiniSurround.user_input("Number of * to find")
    local many_star = string.rep("%*", (tonumber(n_star) or 1))
    return {(many_star .. "().-()" .. many_star)}
  end
  local function _84_()
    local n_star = MiniSurround.user_input("Number of * to output")
    local many_star = string.rep("%*", (tonumber(n_star) or 1))
    return {left = many_star, right = many_star}
  end
  mini_s.setup({mappings = {add = "ys", delete = "ds", find = "", find_left = "", highlight = "", replace = "cs", update_n_lines = "", suffix_last = "", suffix_next = ""}, search_method = "cover_or_next", custom_surroundings = {f = {input = ts_input({outer = "@call.outer", inner = "@call.inner"})}, b = {input = ts_input({outer = "@block.outer", inner = "@block.inner"})}, [")"] = {output = {left = "( ", right = " )"}}, ["*"] = {input = _83_, output = _84_}}})
  vim.keymap.del("x", "ys")
  vim.keymap.set("x", "S", ":<C-u>lua MiniSurround.add('visual')<CR>", {silent = true})
  vim.keymap.set("n", "yss", "ys_", {remap = true})
  local function _85_()
    MiniTrailspace.trim()
    return MiniTrailspace.trim_last_lines()
  end
  vim.api.nvim_create_autocmd({"BufWritePre"}, {pattern = "*", callback = _85_})
  local hermes_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
  local function _86_(ctx)
    local kind_icon, _, _0 = MiniIcons.get("lsp", ctx.kind)
    return kind_icon
  end
  local function _87_(ctx)
    local _, hl, _0 = MiniIcons.get("lsp", ctx.kind)
    return hl
  end
  local function _88_(ctx)
    local _, hl, _0 = MiniIcons.get("lsp", ctx.kind)
    return hl
  end
  require("blink.cmp").setup(({fuzzy = {implementation = "prefer_rust"}, keymap = {["<C-k>"] = {}}, signature = {enabled = true, window = {show_documentation = true}}, sources = {providers = {snippets = {opts = {search_paths = {(hermes_dir .. "/snippets")}}}}}, completion = {menu = {draw = {treesitter = {"lsp"}, columns = {{"kind_icon"}, {"label", "label_description", gap = 1}, {"kind"}}, components = {kind_icon = {text = _86_, highlight = _87_}, kind = {highlight = _88_}}}}, documentation = {auto_show = true}}} or {}))
  local parinfer_filetypes = {"racket", "lisp", "wat", "wasm", "fennel"}
  local function parinfer_apply()
    local function _89_()
      if vim.b.parinfer_on then
        return "ParinferOn"
      else
        return "ParinferOff"
      end
    end
    pcall(vim.cmd, _89_())
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
  local function _90_()
    return parinfer_set(vim.tbl_contains(parinfer_filetypes, vim.bo.filetype))
  end
  vim.api.nvim_create_autocmd("FileType", {callback = _90_})
  vim.api.nvim_create_autocmd("BufEnter", {callback = parinfer_apply})
  local lz = require("lz.n")
  local function _91_()
    return lz.trigger_load("nvim-dap")
  end
  local function _92_()
    return require("neogen").generate()
  end
  local function _93_()
    return require("neogen").setup((nil or {}))
  end
  return lz.load({{"zig.vim", ft = "zig"}, {"vlime", ft = "lisp"}, {"rustaceanvim", ft = "rust", before = _91_}, {"vim-sleuth", event = {"BufReadPost", "BufNewFile"}}, {"vim-wakatime", event = "DeferredUIEnter"}, {"vim-visual-multi", event = "DeferredUIEnter"}, {"vim-wordmotion", event = "DeferredUIEnter"}, {"refactoring.nvim", cmd = "Refactor"}, {"neogen", cmd = "Neogen", keys = {{"<leader>nf", _92_}}, after = _93_}})
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
    local function _96_(err, filename)
      if (not err and (filename == "style.lua")) then
        apply_theme(get_base16())
        return vim.notify("Switched Themes", vim.log.levels.INFO)
      else
        return nil
      end
    end
    vim.uv.fs_event_start(fse, stylix_dir, {}, vim.schedule_wrap(_96_))
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
      set_hl("LineNr", {fg = palette.base0E, bg = palette.base00})
      set_hl("SignColumn", {fg = palette.base03, bg = palette.base00})
      set_hl("NonText", {fg = palette.base02, bg = palette.base00})
      IsTransparent = false
      return nil
    else
      set_hl("Normal", {bg = "NONE"})
      set_hl("LineNr", {fg = palette.base0E, bg = "NONE"})
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
  local function _102_()
    if (vim.bo.filetype == "lisp") then
      sbcl_running_3f = sbcl_pid()
      return nil
    else
      return nil
    end
  end
  vim.api.nvim_create_autocmd({"BufEnter", "FocusGained", "CursorHold"}, {callback = _102_})
  local function esc(s)
    return (s:gsub("%%", "%%%%"))
  end
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
      return ("[" .. esc(table.concat(buf_client_names, ", ")) .. "]")
    end
  end
  local function lsp()
    local count = {}
    local levels = {errors = "Error", warnings = "Warn", info = "Info", hints = "Hint"}
    for k, level in pairs(levels) do
      count[k] = vim.tbl_count(vim.diagnostic.get(0, {severity = level}))
    end
    local _110_
    if (count.errors ~= 0) then
      _110_ = ("%#" .. "DiagnosticError" .. "#" .. tostring(("\239\129\151 " .. count.errors)) .. "%*")
    else
      _110_ = ""
    end
    local _112_
    if (count.warnings ~= 0) then
      _112_ = ("%#" .. "DiagnosticWarn" .. "#" .. tostring(("\239\129\177 " .. count.warnings)) .. "%*")
    else
      _112_ = ""
    end
    local _114_
    if (count.hints ~= 0) then
      _114_ = ("%#" .. "DiagnosticHint" .. "#" .. tostring(("\239\129\154 " .. count.hints)) .. "%*")
    else
      _114_ = ""
    end
    local _116_
    if (count.info ~= 0) then
      _116_ = ("%#" .. "DiagnosticInfo" .. "#" .. tostring(("\239\129\153 " .. count.info)) .. "%*")
    else
      _116_ = ""
    end
    return (_110_ .. _112_ .. _114_ .. _116_ .. "%#Normal#")
  end
  local function git()
    local d = vim.b.gitsigns_status_dict
    if d then
      local _118_
      if (d.added and (d.added > 0)) then
        _118_ = ("%#" .. "GitSignsAdd" .. "#" .. tostring(("+ " .. d.added .. " ")) .. "%*")
      else
        _118_ = ""
      end
      local _120_
      if (d.changed and (d.changed > 0)) then
        _120_ = ("%#" .. "GitSignsChange" .. "#" .. tostring(("~ " .. d.changed .. " ")) .. "%*")
      else
        _120_ = ""
      end
      local _122_
      if (d.removed and (d.removed > 0)) then
        _122_ = ("%#" .. "GitSignsDelete" .. "#" .. tostring(("- " .. d.removed .. " ")) .. "%*")
      else
        _122_ = ""
      end
      return (("%#" .. "GitSignsAdd" .. "#" .. tostring((" \238\156\165 " .. esc(d.head))) .. "%*") .. " " .. _118_ .. _120_ .. _122_)
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
    local _let_128_ = (modes[m] or {"?", "base05", "base00"})
    local text = _let_128_[1]
    local fg = _let_128_[2]
    local bg = _let_128_[3]
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
    local ok_3f, sc
    if (vim.v.hlsearch == 1) then
      ok_3f, sc = pcall(vim.fn.searchcount, {maxcount = 999, timeout = 20})
    else
      ok_3f, sc = nil
    end
    if (ok_3f and sc.total and (sc.total > 0)) then
      local _132_
      do
        local case_131_ = sc.incomplete
        if (case_131_ == 1) then
          _132_ = "?"
        elseif (case_131_ == 2) then
          _132_ = (">" .. sc.maxcount)
        else
          local _ = case_131_
          _132_ = sc.total
        end
      end
      return ("%#Comment#[" .. sc.current .. "/" .. _132_ .. "]%*")
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
  local function typst()
    local errors = vim.b.typst_errors
    if vim.b.typst_watch then
      local _139_
      if (errors > 0) then
        _139_ = ("%#" .. "DiagnosticError" .. "#" .. tostring(("typst " .. errors)) .. "%*")
      else
        _139_ = ("%#" .. "DiagnosticOk" .. "#" .. tostring("typst") .. "%*")
      end
      local _141_
      if vim.b.typst_viewer then
        _141_ = "DiagnosticOk"
      else
        _141_ = "Comment"
      end
      local _143_
      if vim.b.typst_mode then
        _143_ = ("%#" .. "DiagnosticInfo" .. "#" .. tostring(" auto") .. "%*")
      else
        _143_ = ""
      end
      return (_139_ .. " " .. ("%#" .. _141_ .. "#" .. tostring("zathura") .. "%*") .. _143_)
    else
      return ""
    end
  end
  local function nix_shell()
    local env = os.getenv("IN_NIX_SHELL")
    if env then
      local _146_
      do
        local pv_147_, pv_148_ = MiniIcons.get("os", "nixos")
        local icon_2_auto,hl_3_auto = pv_147_, pv_148_
        local _149_
        if hl_3_auto then
          _149_ = ("%#" .. hl_3_auto .. "#")
        else
          _149_ = ""
        end
        _146_ = (_149_ .. (icon_2_auto or "") .. "%*")
      end
      return (_146_ .. ("%#" .. "Comment" .. "#" .. tostring(env) .. "%*"))
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
    local _152_
    if (dir == ".") then
      _152_ = ""
    else
      _152_ = (esc(dir) .. "/")
    end
    local _154_
    if hl then
      _154_ = ("%#" .. hl .. "#")
    else
      _154_ = ""
    end
    local _156_
    if vim.bo.modified then
      _156_ = ("%#" .. "WarningMsg" .. "#" .. tostring("\226\151\143") .. "%*")
    else
      _156_ = ""
    end
    local _158_
    if vim.bo.readonly then
      _158_ = ("%#" .. "DiagnosticError" .. "#" .. tostring("\240\159\148\146") .. "%*")
    else
      _158_ = ""
    end
    return ("%#Comment#" .. _152_ .. "%*" .. (_154_ .. ((icon .. " " .. esc(name)) or "") .. "%*") .. " " .. _156_ .. _158_)
  end
  Statusline.active = function()
    local _160_
    do
      local pv_161_, pv_162_ = MiniIcons.get("file", vim.fn.expand("%"))
      local icon_2_auto,hl_3_auto = pv_161_, pv_162_
      local _163_
      if hl_3_auto then
        _163_ = ("%#" .. hl_3_auto .. "#")
      else
        _163_ = ""
      end
      _160_ = (_163_ .. (icon_2_auto or "") .. "%*")
    end
    return (mode() .. " " .. recording() .. " " .. git() .. " " .. filename() .. " " .. lsp() .. "%=" .. get_attached_clients() .. "%=" .. searchcount() .. " " .. typst() .. " " .. fun() .. " " .. nix_shell() .. " " .. _160_ .. " " .. "%{&filetype != '' ? &filetype : 'text'} " .. " " .. wordcount() .. " " .. "[%P %l:%c]")
  end
  Statusline.inactive = function()
    return "%#Comment# %t%*"
  end
  local group = vim.api.nvim_create_augroup("Statusline", {clear = true})
  local function _165_()
    vim.opt_local.statusline = "%!v:lua.Statusline.active()"
    return nil
  end
  vim.api.nvim_create_autocmd({"WinEnter", "BufEnter"}, {group = group, callback = _165_})
  local function _166_()
    vim.opt_local.statusline = "%!v:lua.Statusline.inactive()"
    return nil
  end
  vim.api.nvim_create_autocmd({"WinLeave", "BufLeave"}, {group = group, callback = _166_})
  local function _167_()
    return vim.cmd.redrawstatus()
  end
  return vim.defer_fn(_167_, 1000)
end
require("fnl.statusline")
package.preload["fnl.tabline"] = package.preload["fnl.tabline"] or function(...)
  local function _168_()
    vim.cmd.redrawtabline()
    return nil
  end
  vim.api.nvim_create_autocmd({"TermRequest", "ModeChanged"}, {desc = "Refresh tabline", callback = _168_})
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
    local function _170_(b)
      return (vim.api.nvim_buf_is_valid(b) and (1 == vim.fn.buflisted(b)) and (vim.api.nvim_buf_get_name(b) ~= ""))
    end
    return vim.tbl_filter(_170_, vim.api.nvim_list_bufs())
  end
  local function buf_diag(buf)
    local e = #vim.diagnostic.get(buf, {severity = vim.diagnostic.severity.ERROR})
    local w = #vim.diagnostic.get(buf, {severity = vim.diagnostic.severity.WARN})
    local _171_
    if (e > 0) then
      _171_ = ("%#" .. "DiagnosticSignError" .. "# " .. tostring(e) .. "%*")
    else
      _171_ = ""
    end
    local _173_
    if (w > 0) then
      _173_ = ("%#" .. "DiagnosticSignWarn" .. "# " .. tostring(w) .. "%*")
    else
      _173_ = ""
    end
    return (_171_ .. _173_)
  end
  local function workspace_diag()
    local e = #vim.diagnostic.get(nil, {severity = vim.diagnostic.severity.ERROR})
    local w = #vim.diagnostic.get(nil, {severity = vim.diagnostic.severity.WARN})
    local h = #vim.diagnostic.get(nil, {severity = vim.diagnostic.severity.HINT})
    local i = #vim.diagnostic.get(nil, {severity = vim.diagnostic.severity.INFO})
    local _175_
    if (e > 0) then
      _175_ = ("%#" .. "DiagnosticSignError" .. "# " .. tostring(e) .. "%*")
    else
      _175_ = ""
    end
    local _177_
    if (w > 0) then
      _177_ = ("%#" .. "DiagnosticSignWarn" .. "# " .. tostring(w) .. "%*")
    else
      _177_ = ""
    end
    local _179_
    if (h > 0) then
      _179_ = ("%#" .. "DiagnosticSignHint" .. "# " .. tostring(h) .. "%*")
    else
      _179_ = ""
    end
    local _181_
    if (i > 0) then
      _181_ = ("%#" .. "DiagnosticSignInfo" .. "# " .. tostring(i) .. "%*")
    else
      _181_ = ""
    end
    return (_175_ .. _177_ .. _179_ .. _181_)
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
      local _185_
      if locked then
        _185_ = " \243\176\140\190"
      else
        _185_ = ""
      end
      local _187_
      if modified then
        _187_ = " \226\151\143"
      else
        _187_ = ""
      end
      status = (_185_ .. _187_)
      local _189_
      if (i <= 9) then
        _189_ = (i .. ":")
      else
        _189_ = ""
      end
      result = (result .. "%#" .. hl .. "# " .. _189_ .. " " .. "%#" .. icon_group .. "#" .. icon .. "%*%#" .. hl .. "# " .. (name:gsub("%%", "%%%%")) .. status .. " " .. buf_diag(buf) .. " %*")
    end
    return (result .. "%=%#TabLineFill# " .. workspace_diag() .. " ")
  end
  vim.o.tabline = "%!v:lua.Tabline.render()"
  vim.o.showtabline = 2
  for i = 1, 9 do
    local function _191_()
      return Tabline["goto"](i)
    end
    vim.keymap.set("n", ("<leader>" .. i), _191_, {desc = ("Go to buffer " .. i)})
  end
  local hidden = false
  local function tabline_update()
    local bufs = listed_bufs()
    if (not hidden and (#bufs > 1)) then
      vim.o.showtabline = 2
    else
      vim.o.showtabline = 0
    end
    return nil
  end
  local function _193_()
    return tabline_update()
  end
  vim.api.nvim_create_autocmd({"BufAdd", "BufDelete", "BufEnter"}, {callback = _193_})
  local function _194_()
    hidden = not hidden
    return tabline_update()
  end
  Tabline.toggle = _194_
  return vim.keymap.set("n", "<leader>tt", Tabline.toggle, {desc = "Toggle tabline"})
end
require("fnl.tabline")
package.preload["fnl.lsp"] = package.preload["fnl.lsp"] or function(...)
  local null_ls = require("null-ls")
  local problems = {{pattern = "\226\128\139", name = "ZERO WIDTH SPACE", replacement = ""}, {pattern = "\194\160", name = "NON-BREAKING SPACE", replacement = " "}, {pattern = "\239\187\191", name = "BYTE ORDER MARK", replacement = ""}, {pattern = "\226\128\141", name = "ZERO WIDTH JOINER", replacement = ""}, {pattern = "\226\128\142", name = "RIGHT-TO-LEFT MARK", replacement = ""}, {pattern = "\226\128\143", name = "LEFT-TO-RIGHT MARK", replacement = ""}}
  local no_problems
  local function _195_(params)
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
  no_problems = {method = null_ls.methods.DIAGNOSTICS, filetypes = {}, generator = {fn = _195_}}
  null_ls.setup({sources = {null_ls.builtins.formatting.fnlfmt, null_ls.builtins.formatting.stylua, null_ls.builtins.formatting.gofmt, null_ls.builtins.formatting.black, null_ls.builtins.formatting.isort, null_ls.builtins.formatting.nixfmt, null_ls.builtins.formatting.clang_format, null_ls.builtins.formatting.typstyle, null_ls.builtins.formatting.just, null_ls.builtins.formatting.gdformat, null_ls.builtins.formatting.dart_format, null_ls.builtins.formatting.prettierd, null_ls.builtins.formatting.cmake_format, null_ls.builtins.diagnostics.gdlint, null_ls.builtins.diagnostics.glslc.with({extra_args = {"--target-env=opengl"}}), null_ls.builtins.diagnostics.qmllint, null_ls.builtins.diagnostics.vale, null_ls.builtins.diagnostics.markdownlint, null_ls.builtins.diagnostics.checkmake, null_ls.builtins.diagnostics.cmake_lint, null_ls.builtins.diagnostics.statix, null_ls.builtins.diagnostics.deadnix, null_ls.builtins.diagnostics.fish, null_ls.builtins.hover.dictionary, null_ls.builtins.hover.printenv, null_ls.builtins.completion.spell, null_ls.builtins.code_actions.statix}})
  null_ls.register(no_problems)
  local function lsp_format_with_fallback(_opts)
    local opts = (_opts or {})
    local bufnr = (opts.bufnr or 0)
    local get_available = require("null-ls.sources").get_available
    local formatters = get_available(vim.bo[bufnr].filetype, null_ls.methods.FORMATTING)
    local null_ls_formats_3f = (nil ~= formatters[1])
    local function _197_(_241)
      return (not null_ls_formats_3f or (_241.name == "null-ls"))
    end
    return vim.lsp.buf.format({bufnr = bufnr, async = (opts.async or false), timeout_ms = (opts.timeout_ms or 1000), filter = _197_})
  end
  local function _198_(args)
    if not vim.b[args.buf].typst_autosaving then
      return lsp_format_with_fallback({timeout_ms = 500})
    else
      return nil
    end
  end
  vim.api.nvim_create_autocmd("BufWritePre", {pattern = "*", callback = _198_})
  local function _200_()
    return lsp_format_with_fallback()
  end
  vim.keymap.set({"n", "v"}, "<leader>cf", _200_)
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
  local function _202_()
    return snacks.picker.lsp_references()
  end
  n("grr", _202_, "[G]oto [R]eferences")
  local function _203_()
    return snacks.picker.lsp_implementations()
  end
  n("gI", _203_, "[G]oto [I]mplementation")
  local function _204_()
    return snacks.picker.lsp_symbols()
  end
  n("<leader>lds", _204_, "[D]ocument [S]ymbols")
  local function _205_()
    return snacks.picker.lsp_workspace_symbols()
  end
  n("<leader>ws", _205_, "[W]orkspace [S]ymbols")
  local function _206_()
    return vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
  end
  n("<leader>ei", _206_, "Toggle Inlay")
  n("K", noice.hover, "Hover Documentation")
  n("<leader>ltd", vim.lsp.buf.type_definition, "Type [D]efinition")
  n("<space>cl", vim.lsp.codelens.run, "[C]ode [L]ens")
  n("<F2>", vim.lsp.buf.rename, "[R]e[n]ame")
  n("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
  n("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
  n("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
  for _, k in ipairs({"asm_lsp", "ast_grep", "bashls", "cir_lsp_server", "clojure_lsp", "fennel_ls", "janet_lsp", "glsl_analyzer", "neocmake", "nixd", "html", "cssls", "fish_lsp", "omnisharp", "tinymist", "ocamllsp", "nushell", "denols", "jsonls", "pyrefly", "racket_langserver", "wasm_language_tools", "wgsl_analyzer", "zls", "matlab_ls", "gopls"}) do
    vim.lsp.enable(k)
  end
  vim.lsp.config("matlab_ls", {settings = {MATLAB = {indexWorkspace = true, installPath = vim.fn.expand("~/apps/matlab/installation/"), matlabConnectionTiming = "onStart", telemetry = true}}})
  vim.lsp.config("nixd", {settings = {nixd = {nixpkgs = {expr = (vim.g.nix_nixd_nixpkgs or "import <nixpkgs> {}")}, options = {nixos = {expr = vim.g.nix_nixd_nixos_options}, ["home-manager"] = {expr = vim.g.nix_nixd_home_manager_options}}, formatting = {command = {"nixfmt"}}, diagnostic = {suppress = {"sema-escaping-with"}}}}})
  return vim.lsp.config("zls", {settings = {zls = {enable_build_on_save = true, inlay_hints_hide_redundant_param_names = true, inlay_hints_hide_redundant_param_names_last_token = true, warn_style = true, highlight_global_var_declarations = true, build_on_save_args = {"-fincremental", "-j4"}}}})
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
      local function _208_()
        return vim.fn.input("Path to executable: ", (vim.fn.getcwd() .. "/"), "file")
      end
      pick_2_auto = _208_
      local function _209_()
        local name_3_auto = vim.fn.input("Executable name (filter): ")
        return require("dap.utils").pick_process({filter = name_3_auto})
      end
      dap.configurations.c = {{args = {}, cwd = "${workspaceFolder}", name = "Launch", program = pick_2_auto, request = "launch", stopAtBeginningOfMainSubprogram = false, type = "gdb"}, {cwd = "${workspaceFolder}", name = "Select and attach to process", pid = _209_, program = pick_2_auto, request = "attach", type = "gdb"}, {cwd = "${workspaceFolder}", name = "Attach to gdbserver :1234", program = pick_2_auto, request = "attach", target = "localhost:1234", type = "gdb"}}
    end
    dap.configurations.cpp = dap.configurations.c
    dap.configurations.zig = dap.configurations.c
    do
      local pick_2_auto
      local function _210_()
        return vim.fn.input("Path to executable: ", (vim.fn.getcwd() .. "/"), "file")
      end
      pick_2_auto = _210_
      local function _211_()
        local name_3_auto = vim.fn.input("Executable name (filter): ")
        return require("dap.utils").pick_process({filter = name_3_auto})
      end
      dap.configurations.rust = {{args = {}, cwd = "${workspaceFolder}", name = "Launch", program = pick_2_auto, request = "launch", stopAtBeginningOfMainSubprogram = false, type = "rust-gdb"}, {cwd = "${workspaceFolder}", name = "Select and attach to process", pid = _211_, program = pick_2_auto, request = "attach", type = "rust-gdb"}, {cwd = "${workspaceFolder}", name = "Attach to gdbserver :1234", program = pick_2_auto, request = "attach", target = "localhost:1234", type = "rust-gdb"}}
    end
    local keymap_restore = {}
    local sessions = 0
    dap.listeners.after.event_initialized.me = function()
      sessions = (sessions + 1)
      if (sessions == 1) then
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
        local function _214_()
          return frontend.hover()
        end
        return vim.keymap.set("n", "K", _214_, {silent = true})
      else
        return nil
      end
    end
    dap.listeners.after.event_terminated.me = function()
      if (sessions > 0) then
        sessions = (sessions - 1)
        if (sessions == 0) then
          vim.keymap.del("n", "K")
          for _, keymap in ipairs(keymap_restore) do
            if (keymap.buffer == 0) then
              vim.fn.mapset(keymap)
            else
              if vim.api.nvim_buf_is_valid(keymap.buffer) then
                local function _216_()
                  return vim.fn.mapset(keymap)
                end
                vim.api.nvim_buf_call(keymap.buffer, _216_)
              else
              end
            end
          end
          keymap_restore = {}
          return nil
        else
          return nil
        end
      else
        return nil
      end
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
    vim.keymap.set("n", "<leader>det", require("nvim-dap-virtual-text").toggle, {desc = "Dap virt text toggle"})
    for name, sign in pairs({DapBreakpoint = {text = "\239\134\146", texthl = "DiagnosticError", linehl = "", numhl = ""}, DapBreakpointCondition = {text = "\239\129\153", texthl = "DiagnosticWarn", linehl = "", numhl = ""}, DapBreakpointRejected = {text = "\239\129\170", texthl = "DiagnosticError", linehl = "", numhl = ""}, DapLogPoint = {text = "\243\176\134\136", texthl = "DiagnosticInfo", linehl = "", numhl = ""}, DapStopped = {text = "\239\129\161", texthl = "DiagnosticWarn", linehl = "CursorLine", numhl = "DiagnosticWarn"}}) do
      vim.fn.sign_define(name, sign)
    end
    return nil
  end
  local function _221_()
    for _, p in ipairs({"nvim-dap-view", "nvim-dap-virtual-text"}) do
      vim.cmd.packadd(p)
    end
    return nil
  end
  return require("lz.n").load({"nvim-dap", keys = {"<leader>db", "<leader>dc", "<leader>do", "<leader>di", "<leader>dt", "<leader>dr", "<M-c>", "<M-o>", "<M-i>", "<M-t>", "<M-r>", "<leader>dui", "<leader>dux", "<leader>det"}, cmd = {"DapContinue", "DapNew", "DapToggleBreakpoint"}, before = _221_, after = setup})
end
require("fnl.dap")
local function _222_(opts)
  return vim.print(Fennel.eval(opts.args))
end
return vim.api.nvim_create_user_command("Fnl", _222_, {nargs = "+"})
