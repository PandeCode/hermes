local cursor_vfx = { "railgun", "torpedo", "pixiedust", "sonicboom", "ripple", "wireframe" }

vim.g.neovide_cursor_vfx_mode = cursor_vfx[math.random(1, #cursor_vfx)]

vim.keymap.set("n", "<F11>", function()
	vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen
end, {})

vim.g.neovide_scale_factor = 0.78 -- 1

vim.g.neovide_floating_blur_amount_x = 10.0 -- 2.0
vim.g.neovide_floating_blur_amount_y = 10.0 -- 2.0

vim.g.neovide_opacity = 0.8 -- 0

-- vim.g.neovide_scroll_animation_length = -- 0.3

vim.g.neovide_hide_mouse_when_typing = true -- false

vim.g.neovide_refresh_rate = 24
vim.g.neovide_refresh_rate_idle = 1
vim.g.neovide_no_idle = false

vim.g.neovide_confirm_quit = false -- true

vim.g.neovide_floating_corner_radius = 0.5

vim.g.neovide_title_background_color =
	string.format("%x", vim.api.nvim_get_hl(0, { id = vim.api.nvim_get_hl_id_by_name("Normal") }).bg)

vim.keymap.set("n", "<C-+>", function()
	vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + 0.1
end, { silent = true })
vim.keymap.set("n", "<C-=>", function()
	vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + 0.1
end, { silent = true })
vim.keymap.set("n", "<C-->", function()
	vim.g.neovide_scale_factor = vim.g.neovide_scale_factor - 0.1
end, { silent = true })
vim.keymap.set("n", "<C-0>", function()
	vim.g.neovide_scale_factor = 1
end)
