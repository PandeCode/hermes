vim.loader.enable()
package.preload["fnl.options"] = package.preload["fnl.options"] or function(...)
  vim.filetype.add({extension = {fnl = "fennel"}})
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
    local function _1_()
      vim.cmd.edit("%")
      return vim.treesitter.start()
    end
    n("<leader>fe", _1_)
    n("<leader>fs", "<cmd>w<cr>")
    n("<leader>fw", "<cmd>noautocmd w<cr>")
    n("<leader>li", "<cmd>LspInfo<cr>", noremap_silent)
    n("<leader>lq", "<cmd>LspStop<cr>", noremap_silent)
    n("<leader>lr", "<cmd>LspRestart<cr>", noremap_silent)
    n("<leader>ls", "<cmd>LspStart<cr>", noremap_silent)
    n("<leader>me", vim.cmd.messages, nil)
    n("<leader>bp", vim.cmd.bp, noremap_silent)
    n("<leader>bn", vim.cmd.bn, noremap_silent)
    n("<leader>bo", "<cmd>%bd|e#<cr>", noremap_silent)
    n("<A-d>", vim.cmd.bd, noremap_silent)
    n("<leader>c<leader>", "<cmd>normal gcc<cr>", noremap_silent)
    v("<leader>c<leader>", "gc", noremap_silent)
    v("<leader>`", "<cmd>edit #<cr>", noremap_silent)
    n("<leader>gf", "<cmd>e <cfile><cr>")
    n("<leader><F2>", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/g<Left><Left>")
    local function _2_()
      if (vim.fn.mode() == "V") then
        return "^<C-v>I"
      else
        return "I"
      end
    end
    x("I", _2_, {expr = true})
    local function _4_()
      if (vim.fn.mode() == "V") then
        return "$<C-v>A"
      else
        return "A"
      end
    end
    x("A", _4_, {expr = true})
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
    local function _6_()
      if ((vim.g.showtabline == nil) or (vim.g.showtabline == 2)) then
        vim.g.showtabline = 0
        return vim.cmd("set showtabline=0")
      else
        vim.g.showtabline = 2
        return vim.cmd("set showtabline=2")
      end
    end
    n("<leader>tt", _6_, noremap)
  end
  return nil
end
require("fnl.keymaps")
package.preload["fnl.autocmds"] = package.preload["fnl.autocmds"] or function(...)
  local function _8_()
    local data = vim.fn.stdpath("data")
    local cwd = vim.fn.getcwd()
    cwd = (vim.fs.root(cwd, ".git") or cwd)
    local cwd_b64 = vim.base64.encode(cwd)
    local file = vim.fs.joinpath(data, "project_shada", cwd_b64)
    vim.fn.mkdir(vim.fs.dirname(file), "p")
    return file
  end
  vim.opt.shadafile = _8_()
  local function _9_()
    return pcall(vim.treesitter.start)
  end
  vim.api.nvim_create_autocmd({"BufEnter", "BufWrite", "BufWritePost", "BufRead"}, {callback = _9_})
  vim.api.nvim_create_autocmd("TextYankPost", {callback = vim.hl.on_yank})
  local function _10_()
    return vim.fn.mkdir(vim.fn.expand("<afile>:p:h"), "p")
  end
  vim.api.nvim_create_autocmd({"BufWritePre"}, {pattern = "*", callback = _10_})
  vim.opt.number = true
  vim.opt.relativenumber = true
  local function _11_()
    vim.opt.relativenumber = false
    return nil
  end
  vim.api.nvim_create_autocmd("InsertEnter", {pattern = "*", callback = _11_})
  local function _12_()
    vim.opt.relativenumber = true
    return nil
  end
  vim.api.nvim_create_autocmd("InsertLeave", {pattern = "*", callback = _12_})
  vim.cmd("\nif argc() > 1\n\tsilent blast \" load last buffer\n\tsilent bfirst \" switch back to the first\nendif\n\nif exists('+termguicolors')\n\tlet &t_8f=\"\\<Esc>[38;2;%lu;%lu;%lum\"\n\tlet &t_8b=\"\\<Esc>[48;2;%lu;%lu;%lum\"\n\tset termguicolors\nendif\n\nsyntax sync minlines=256\n\n\" Allow saving of files as sudo when I forgot to start vim using sudo.\ncnoremap w!! execute 'write !sudo tee % >/dev/null' <bar> edit!\n")
  local function _13_()
    local filename = vim.fn.expand("%")
    vim.cmd("!git add %")
    return vim.notify(("Git added '" .. filename .. "'"))
  end
  vim.api.nvim_create_user_command("Gitadd", _13_, {})
  local function _14_()
    local filename = vim.fn.expand("%")
    vim.cmd("!chmod +x %")
    return vim.notify(("Given execution rights to '" .. filename .. "'"))
  end
  vim.api.nvim_create_user_command("Chmodx", _14_, {})
  local function _15_()
    return vim.cmd("!rm -f %")
  end
  vim.api.nvim_create_user_command("Rmf", _15_, {})
  return vim.cmd("\ncnoreabbrev W w\ncnoreabbrev Q q\ncnoreabbrev WQ wq\ncnoreabbrev Wq wq\ncnoreabbrev WQA wqa\ncnoreabbrev Wqa wqa\ncnoreabbrev QA qa\ncnoreabbrev Qa qa\ncnoreabbrev E e\ncnoreabbrev gitadd Gitadd\ncnoreabbrev chmodx Chmodx\ncnoreabbrev rmf Rmf\n")
end
require("fnl.autocmds")
package.preload["fnl.plugins"] = package.preload["fnl.plugins"] or function(...)
  if (vim.g.nix_plugins == nil) then
  else
  end
  local plugins = {}
  vim.pack.add(plugins, {load = require("lz.n").load})
  for _, k in ipairs({"emmylua_ls", "fennel_ls"}) do
    vim.lsp.enable(k)
  end
  local function _17_()
    return pcall(vim.treesitter.start)
  end
  vim.api.nvim_create_autocmd({"BufEnter", "BufWrite", "BufWritePost"}, {callback = _17_})
  vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  local ts_ctx = require("treesitter-context")
  ts_ctx.setup({enable = true, multiwindow = true})
  local function _18_()
    return ts_ctx.go_to_context(vim.v.count1)
  end
  vim.keymap.set("n", "[c", _18_, {silent = true})
  local ts_obj = require("nvim-treesitter-textobjects")
  ts_obj.setup({move = {set_jumps = true}})
  require("nvim-treesitter.config").setup(({highlight = {enable = true}, indent = {enable = true}, incremental_selection = {enable = true, keymaps = {init_selection = "<c-space>", node_incremental = "<c-space>", scope_incremental = "<c-s>", node_decremental = "<M-space>"}}, textobjects = {select = {enable = true, lookahead = true, keymaps = {aa = "@parameter.outer", ia = "@parameter.inner", af = "@function.outer", ["if"] = "@function.inner", ac = "@class.outer", ic = "@class.inner"}}, move = {enable = true, set_jumps = true, goto_next_start = {["]m"] = "@function.outer", ["]]"] = "@class.outer"}, goto_next_end = {["]M"] = "@function.outer", ["]["] = "@class.outer"}, goto_previous_start = {["[m"] = "@function.outer", ["[["] = "@class.outer"}, goto_previous_end = {["[M"] = "@function.outer", ["[]"] = "@class.outer"}}, swap = {enable = true, swap_next = {["<leader>a"] = "@parameter.inner"}, swap_previous = {["<leader>A"] = "@parameter.inner"}}}} or {}))
  require("snacks").setup({bigfile = {enabled = true}, dashboard = {enabled = false}, explorer = {enabled = true}, indent = {enabled = true}, input = {enabled = true}, picker = {enabled = true}, notifier = {enabled = true}, quickfile = {enabled = true}, scope = {enabled = true}, scroll = {enabled = true}, statuscolumn = {enabled = true}, words = {enabled = true}})
  local function sk(c)
    local function _19_()
      return Snacks.picker[c]()
    end
    return _19_
  end
  for _, v in ipairs({{"<leader>ff", sk("files"), "Find Files"}, {"<leader>fr", sk("grep"), "Grep"}, {"<leader>fm", sk("marks"), "Marks"}, {"<leader>fn", sk("man"), "Man"}, {"<leader><space>", sk("smart"), "Smart Find Files"}, {"<leader>fb", sk("buffers"), "Buffers"}, {"<leader>ch", sk("cliphist"), "cliphist"}, {"<leader>fll", sk("loclist"), "loclist"}, {"<leader>fq", sk("qflist"), "qflist"}, {"<leader>fld", sk("lsp_declarations"), "lsp_declarations"}, {"<leader>fle", sk("lsp_definitions"), "lsp_definitions"}, {"<leader>fli", sk("lsp_implementations"), "lsp_implementations"}, {"<leader>flr", sk("lsp_references"), "lsp_references"}, {"<leader>fls", sk("lsp_symbols"), "lsp_symbols"}, {"<leader>nh", Snacks.notifier.hide, "Notifier Hide"}, {"<leader>nh", Snacks.notifier.show_history, "Notifier Show"}}) do
    vim.keymap.set("n", v[1], v[2], {desc = v[3]})
  end
  require("noice").setup(({lsp = {override = {["vim.lsp.util.convert_input_to_markdown_lines"] = true, ["vim.lsp.util.stylize_markdown"] = true}}, presets = {bottom_search = true, command_palette = true, long_message_to_split = true, inc_rename = false, lsp_doc_border = false}} or {}))
  require("mini.icons").setup((nil or {}))
  require("mini.cursorword").setup((nil or {}))
  require("mini.pairs").setup((nil or {}))
  require("mini.align").setup((nil or {}))
  require("mini.move").setup((nil or {}))
  require("mini.splitjoin").setup((nil or {}))
  require("mini.trailspace").setup((nil or {}))
  local function _20_()
    MiniTrailspace.trim()
    return MiniTrailspace.trim_last_lines()
  end
  vim.api.nvim_create_autocmd({"BufWritePre"}, {pattern = "*", callback = _20_})
  local capabilities = require("blink.cmp").get_lsp_capabilities({textDocument = {foldingRange = {lineFoldingOnly = true, dynamicRegistration = false}}})
  require("blink.pairs").setup((nil or {}))
  require("blink.indent").setup((nil or {}))
  require("blink.cmp").setup(({} or {}))
  local null_ls = require("null-ls")
  local problems = {{pattern = "\226\128\139", name = "ZERO WIDTH SPACE", replacement = ""}, {pattern = "\194\160", name = "NON-BREAKING SPACE", replacement = " "}, {pattern = "\239\187\191", name = "BYTE ORDER MARK", replacement = ""}, {pattern = "\226\128\141", name = "ZERO WIDTH JOINER", replacement = ""}, {pattern = "\226\128\142", name = "RIGHT-TO-LEFT MARK", replacement = ""}, {pattern = "\226\128\143", name = "LEFT-TO-RIGHT MARK", replacement = ""}}
  local no_problems
  local function _21_(params)
    local diagnostics = {}
    for i, line in ipairs(params.content) do
      for _, problem in ipairs(problems) do
        local _local_22_ = line:find(problem.pattern)
        local col = _local_22_[1]
        local end_col = _local_22_[2]
        if (col and end_col) then
          table.insert(diagnostics, {row = i, col = col, end_col = (end_col + 1), source = "no-problems", message = problem.name, severity = vim.diagnostic.severity.WARN})
        else
        end
      end
    end
    return diagnostics
  end
  no_problems = {method = null_ls.methods.DIAGNOSTICS, filetypes = {"*"}, generator = {fn = _21_}}
  null_ls.setup({sources = {null_ls.builtins.formatting.fnlfmt, null_ls.builtins.formatting.stylua, null_ls.builtins.formatting.gofmt, null_ls.builtins.formatting.black, null_ls.builtins.formatting.isort, null_ls.builtins.formatting.alejandra, null_ls.builtins.formatting.nixfmt, null_ls.builtins.formatting.clang_format, null_ls.builtins.formatting.typstyle, null_ls.builtins.formatting.just, null_ls.builtins.formatting.gdformat, null_ls.builtins.formatting.dart_format, null_ls.builtins.formatting.prettierd, null_ls.builtins.formatting.cmake_format, null_ls.builtins.diagnostics.gdlint, null_ls.builtins.diagnostics.glslc.with({extra_args = {"--target-env=opengl"}}), null_ls.builtins.diagnostics.qmllint, null_ls.builtins.diagnostics.vale, null_ls.builtins.diagnostics.markdownlint, null_ls.builtins.diagnostics.checkmake, null_ls.builtins.diagnostics.cmake_lint, null_ls.builtins.diagnostics.statix, null_ls.builtins.diagnostics.deadnix, null_ls.builtins.diagnostics.fish, null_ls.builtins.hover.dictionary, null_ls.builtins.hover.printenv, null_ls.builtins.completion.spell, null_ls.builtins.code_actions.statix, null_ls.builtins.code_actions.ts_node_action}})
  null_ls.register(no_problems)
  local function lsp_format_with_fallback(opts)
    return vim.lsp.buf.format({bufnr = (opts.bufnr or 0), async = (opts.async or false), timeout_ms = (opts.timeout_ms or 1000)})
  end
  local function _24_()
    return lsp_format_with_fallback({timeout_ms = 500})
  end
  vim.api.nvim_create_autocmd("BufWritePre", {pattern = "*", callback = _24_})
  local function _25_()
    return lsp_format_with_fallback()
  end
  vim.keymap.set({"n", "v"}, "<leader>cf", _25_)
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
  local function _27_()
    return snacks.picker.lsp_references()
  end
  n("gr", _27_, "[G]oto [R]eferences")
  local function _28_()
    return snacks.picker.lsp_implementations()
  end
  n("gI", _28_, "[G]oto [I]mplementation")
  local function _29_()
    return snacks.picker.lsp_symbols()
  end
  n("<leader>ds", _29_, "[D]ocument [S]ymbols")
  local function _30_()
    return snacks.picker.lsp_workspace_symbols()
  end
  n("<leader>ws", _30_, "[W]orkspace [S]ymbols")
  local function _31_()
    return vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
  end
  n("<leader>ei", _31_, "Toggle Inlay")
  n("K", noice.hover, "Hover Documentation")
  n("<leader>d", vim.lsp.buf.type_definition, "Type [D]efinition")
  n("<space>cl", vim.lsp.codelens.run, "[C]ode [L]ens")
  n("<F2>", vim.lsp.buf.rename, "[R]e[n]ame")
  n("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
  n("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
  return n("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
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
  return nil
end
require("fnl.theme")
package.preload["fnl.statusline"] = package.preload["fnl.statusline"] or function(...)
  Statusline = {}
  local function get_attached_clients()
    local buf_clients = vim.lsp.get_clients({bufnr = 0})
    if (#buf_clients == 0) then
      return "No client active"
    else
      local buf_ft = vim.bo.filetype
      local buf_client_names = {}
      local num_client_names = #buf_client_names
      for _, client in pairs(buf_clients) do
        num_client_names = (num_client_names + 1)
        buf_client_names[num_client_names] = client.name
      end
      do
        local ok_3f, null_ls = pcall(require, "null-ls")
        if ok_3f then
          local sources = null_ls.get_sources()
          for _, source in ipairs(sources) do
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
      local and_36_ = ("lisp" == buf_ft)
      if and_36_ then
        local function _37_()
          return false
        end
        and_36_ = _37_()
      end
      if and_36_ then
        table.insert(buf_client_names, "sbcl")
      else
      end
      return ("[" .. table.concat(buf_client_names, ", ") .. "]")
    end
  end
  
  local function lsp()
    local count = {}
    local levels = {
      errors = "Error",
      warnings = "Warn",
      info = "Info",
      hints = "Hint",
    }
  
    for k, level in pairs(levels) do
      count[k] = vim.tbl_count(vim.diagnostic.get(0, { severity = level }))
    end
  
    local errors = ""
    local warnings = ""
    local hints = ""
    local info = ""
  
    if count["errors"] ~= 0 then
      errors = " %#LspDiagnosticsSignError# " .. count["errors"]
    end
    if count["warnings"] ~= 0 then
      warnings = " %#LspDiagnosticsSignWarning# " .. count["warnings"]
    end
    if count["hints"] ~= 0 then
      hints = " %#LspDiagnosticsSignHint# " .. count["hints"]
    end
    if count["info"] ~= 0 then
      info = " %#LspDiagnosticsSignInformation# " .. count["info"]
    end
  
    return errors .. warnings .. hints .. info .. "%#Normal#"
  end
  
    
  local function lsp()
    local count = {}
    local levels = {errors = "Error", warnings = "Warn", info = "Info", hints = "Hint"}
    for k, level in pairs(levels) do
      count[k] = vim.tbl_count(vim.diagnostic.get(0, {severity = level}))
    end
    local errors = ""
    local warnings = ""
    local hints = ""
    local info = ""
    if (count.errors ~= 0) then
      errors = (" %#DiagnosticSignError#\239\153\152 " .. count.errors)
    else
    end
    if (count.warnings ~= 0) then
      warnings = (" %#DiagnosticSignWarn#\239\129\177 " .. count.warnings)
    else
    end
    if (count.hints ~= 0) then
      hints = (" %#DiagnosticSignHint#\239\160\180 " .. count.hints)
    else
    end
    if (count.info ~= 0) then
      info = (" %#DiagnosticSignInfo#\239\159\187 " .. count.info)
    else
    end
    return (errors .. warnings .. hints .. info .. "%#Normal#")
  end
  local function git()
    local d = vim.b.gitsigns_status_dict
    if d then
      local _44_
      if d.added then
        if (d.added > 0) then
          _44_ = ("%#" .. "GitSignsAdd" .. "#" .. tostring(("+ " .. d.added)) .. "%*")
        else
          _44_ = ""
        end
      else
        _44_ = ""
      end
      local _47_
      if d.changed then
        if (d.changed > 0) then
          _47_ = ("%#" .. "GitSignsChange" .. "#" .. tostring(("~ " .. d.changed)) .. "%*")
        else
          _47_ = ""
        end
      else
        _47_ = ""
      end
      local _50_
      if d.removed then
        if (d.removed > 0) then
          _50_ = ("%#" .. "GitSignsRemove" .. "#" .. tostring(("- " .. d.removed)) .. "%*")
        else
          _50_ = ""
        end
      else
        _50_ = ""
      end
      return (d.head .. " " .. _44_ .. " " .. _47_ .. " " .. _50_)
    else
      return ""
    end
  end
  Statusline.active = function()
    local _54_
    do
      local pv_55_, pv_56_ = MiniIcons.get("os", "nixos")
      local icon_2_auto,hl_3_auto = pv_55_, pv_56_
      local _57_
      if hl_3_auto then
        _57_ = ("%#" .. hl_3_auto .. "#")
      else
        _57_ = ""
      end
      _54_ = (_57_ .. (icon_2_auto or "") .. "%*")
    end
    local _59_
    do
      local pv_60_, pv_61_ = MiniIcons.get("file", (vim.fn.expand("%") or "default"))
      local icon_2_auto,hl_3_auto = pv_60_, pv_61_
      local _62_
      if hl_3_auto then
        _62_ = ("%#" .. hl_3_auto .. "#")
      else
        _62_ = ""
      end
      _59_ = (_62_ .. (icon_2_auto or "") .. "%*")
    end
    return ("%f" .. lsp() .. git() .. "%=" .. get_attached_clients() .. "%=" .. " " .. _54_ .. " " .. _59_ .. " " .. "%{&filetype != '' ? &filetype : 'text'} " .. "[%P %l:%c]")
  end
  Statusline.inactive = function()
    return ("" .. " %t")
  end
  local group = vim.api.nvim_create_augroup("Statusline", {clear = true})
  local function _64_()
    vim.opt_local.statusline = "%!v:lua.Statusline.active()"
    return nil
  end
  vim.api.nvim_create_autocmd({"WinEnter", "BufEnter"}, {group = group, callback = _64_})
  local function _65_()
    vim.opt_local.statusline = "%!v:lua.Statusline.inactive()"
    return nil
  end
  vim.api.nvim_create_autocmd({"WinLeave", "BufLeave"}, {group = group, callback = _65_})
  local function _66_()
    return vim.cmd.redrawstatus()
  end
  return vim.defer_fn(_66_, 1000)
end
require("fnl.statusline")
vim.diagnostic.config({virtual_text = true, virtual_lines = {current_line = true}, underline = true, update_in_insert = false})
local og_virt_text = nil
local og_virt_line = nil

 vim.api.nvim_create_autocmd({ "CursorMoved", "DiagnosticChanged" }, {
 	group = vim.api.nvim_create_augroup("diagnostic_only_virtlines", {}),
 	callback = function()
 		if og_virt_line == nil then
 			og_virt_line = vim.diagnostic.config().virtual_lines
 		end

 		-- ignore if virtual_lines.current_line is disabled
 		if not (og_virt_line and og_virt_line.current_line) then
 			if og_virt_text then
 				vim.diagnostic.config({ virtual_text = og_virt_text })
 				og_virt_text = nil
 			end
 			return
 		end

 		if og_virt_text == nil then
 			og_virt_text = vim.diagnostic.config().virtual_text
 		end

 		local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1

 		if vim.tbl_isempty(vim.diagnostic.get(0, { lnum = lnum })) then
 			vim.diagnostic.config({ virtual_text = og_virt_text })
 		else
 			vim.diagnostic.config({ virtual_text = false })
 		end
 	end,
 })

local function _67_()
  return pcall(vim.diagnostic.show)
end
vim.api.nvim_create_autocmd("ModeChanged", {group = vim.api.nvim_create_augroup("diagnostic_redraw", {}), callback = _67_})

local wrap_format_stop_blocks = {
	{ "lua", "-- stylua: ignore start", "-- stylua: ignore end" },
	{ "python", "# fmt: off", "# fmt: on" },
	{ { "haskell", "lhaskell" }, "{- ORMOLU_DISABLE -}", "{- ORMOLU_ENABLE -}" },
	{ { "cpp", "c" }, "// clang-format off", "// clang-format on" },
}

local top_format_stop_blocks = {
	{
		{
			"js",
			"ts",
			"tsx",
			"jsx",
			"vue",
			"json",
			"svelte",
			"javascript",
			"typescript",
			"javascriptreact",
			"typescriptreact",
		},
		"// prettier-ignore",
	},
	{ "rust", "#[rustfmt::skip]" },
	{ "fennel", ";; fnlfmt: skip" },
}

function add_wrap_format_stop_block(filetypes, start, stop)
	filetypes = type(filetypes) == "table" and filetypes or { filetypes }

	vim.api.nvim_create_autocmd("Filetype", {
		pattern = filetypes,
		callback = function(tbl)
			vim.keymap.set(
				"v",
				"<SPACE>fo",
				"vnoremap <buffer> <SPACE>fo <esc>`>a" .. stop .. "<esc>`<i" .. start .. "<esc>",
				{ buffer = tbl.buf }
			)
		end,
	})

	vim.api.nvim_create_autocmd("Filetype", {
		pattern = filetypes,
		callback = function(tbl)
			vim.keymap.set("n", "<SPACE>fo", "<esc>{o" .. start .. "<esc>}O" .. stop .. "<esc>", { buffer = tbl.buf })
		end,
	})
end

function add_top_format_stop_block(filetypes, top)
	filetypes = type(filetypes) == "table" and filetypes or { filetypes }

	vim.api.nvim_create_autocmd("Filetype", {
		pattern = filetypes,
		callback = function(tbl)
			vim.keymap.set("v", "<SPACE>fo", "<esc>`<i" .. top .. "<esc>", { buffer = tbl.buf })
		end,
	})

	vim.api.nvim_create_autocmd("Filetype", {
		pattern = filetypes,
		callback = function(tbl)
			vim.keymap.set("n", "<SPACE>fo", "<esc>{o" .. top .. "<esc>", { buffer = tbl.buf })
		end,
	})
end

for _, wrap_format_stop_block in ipairs(wrap_format_stop_blocks) do
	add_wrap_format_stop_block(wrap_format_stop_block[1], wrap_format_stop_block[2], wrap_format_stop_block[3])
end

for _, top_format_stop_block in ipairs(top_format_stop_blocks) do
	add_top_format_stop_block(top_format_stop_block[1], top_format_stop_block[2])
end
     
return nil

