if vim.g.started_by_firenvim ~= true then
	return
end

-- read by firenvim#run, which the browser calls after startup. <C-e> opens the
-- editor anywhere; typst.app's editor (CodeMirror 6) opens on its own. the
-- patterns are javascript regexes on the full url
vim.g.firenvim_config = {
	globalSettings = vim.empty_dict(),
	localSettings = {
		[".*"] = { takeover = "never", priority = 0 },
		["^https://typst\\.app/project/"] = {
			takeover = "always",
			selector = ".cm-content",
			-- the .typ is what gives the buffer the typst filetype and tinymist
			filename = "{hostname}_{pathname%32}.typ",
			priority = 1,
		},
	},
}

-- an opt plugin, the browser runs nvim -c "call firenvim#run()"
vim.cmd.packadd("firenvim")

vim.o.cmdheight = 0
vim.o.tabline = ""
vim.o.showtabline = 0
vim.o.statusline = ""
vim.o.laststatus = 0

-- firenvim sends the buffer to the page on write, so typst buffers write a
-- moment after each change to keep typst.app's preview live. the autosaving
-- flag keeps format on save from rewriting the text while typing
local sync_ms = 300
local timer = vim.uv.new_timer()

local function sync(buf)
	if not vim.api.nvim_buf_is_valid(buf) or not vim.bo[buf].modified then
		return
	end
	vim.b[buf].typst_autosaving = true
	vim.api.nvim_buf_call(buf, function()
		vim.cmd("silent! write")
	end)
	vim.b[buf].typst_autosaving = nil
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = "typst",
	callback = function(args)
		vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
			buffer = args.buf,
			callback = function()
				timer:stop()
				timer:start(sync_ms, 0, vim.schedule_wrap(function()
					sync(args.buf)
				end))
			end,
		})
	end,
})
