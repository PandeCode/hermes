local options = {

	visual = {
		inccommand = "split",
		breakindent = true,
		number = true,
		relativenumber = true,
		termguicolors = true,
		cursorline = true,
		signcolumn = "yes",
		colorcolumn = "80",
		list = true,
		listchars = "tab:→ ,lead:·,trail:·,nbsp:␣",
		pumblend = 20,
		winblend = 20,
		showmatch = true,
		scrolloff = 8,
		sidescrolloff = 8,
		laststatus = 3,
	},

	editing = {
		expandtab = true,
		shiftwidth = 4,
		tabstop = 4,
		softtabstop = 4,
		smartindent = true,
		autoindent = true,
		smarttab = true,
		wrap = true,
		linebreak = true,
		formatoptions = "jcroqlnt",
		conceallevel = 1,
		virtualedit = "block",
		completeopt = "menu,menuone,noselect",
	},

	search = {
		hlsearch = true,
		incsearch = true,
		ignorecase = true,
		smartcase = true,
		inccommand = "nosplit",
		gdefault = true,
	},

	files = {
		backup = false,
		writebackup = false,
		swapfile = false,
		undofile = true,
		undodir = vim.fs.normalize("~/.cache/nvim/undodir"),
		hidden = true,
		confirm = true,
		autoread = true,
		fileencoding = "utf-8",
		encoding = "UTF-8",
	},

	interface = {
		mouse = "a",
		updatetime = 100,
		timeoutlen = 500,
		ttimeoutlen = 10,
		history = 1000,
		cmdheight = 1,
		splitbelow = true,
		splitright = true,
		guifont = "FantasqueSansM Nerd Font:h14",
		guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175",
		visualbell = true,
		title = true,
		shortmess = "filnxtToOFIc",
	},

	spelling = {
		spell = true,
		spelllang = "en_us",
	},

	performance = {
		synmaxcol = 240,
		ttyfast = true,
		redrawtime = 1000,
	},

	misc = {
		wildignore = table.concat({
			"*.pyc",
			"*_build/*",
			"**/coverage/*",
			"**/Debug/*",
			"**/build/*",
			"**/node_modules/*",
			"**/android/*",
			"**/ios/*",
			"**/.git/*",
			"*.lock",
			"*.aux",
			"*.bbl",
			"*.bcf",
			"*.blg",
			"*.fdb_latexmk",
			"*.fls",
			"*.log",
			"*.pdf",
			"*.run.xml",
			"*.synctex.gz",
			"*.tex",
			"*.toc",
			"*.DS_Store",
			"*.class",
			"*.out",
		}, ","),
		wildmode = "longest:full,full",
		wildmenu = true,
		backspace = "indent,eol,start",

		showmode = false,
		showcmd = true,
		ruler = true,
	},
}

for category, settings in pairs(options) do
	for option, value in pairs(settings) do
		vim.opt[option] = value
	end
end

local disabled_built_ins = {
	"netrwPlugin",
	"netrw",
	"gzip",
	"zip",
	"zipPlugin",
	"tar",
	"tarPlugin",
	"getscript",
	"getscriptPlugin",
	"vimball",
	"vimballPlugin",
	"2html_plugin",
	"logipat",
	"rrhelper",
	"spellfile_plugin",
	"matchit",
}

for _, plugin in pairs(disabled_built_ins) do
	vim.g["loaded_" .. plugin] = 1
end
