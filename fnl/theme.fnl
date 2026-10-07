(local stylix-dir (vim.fs.normalize "~/.config/stylix"))

(fn get_base16 []
  (let [(ok? val) (pcall dofile (.. stylix-dir :/style.lua))]
    (if ok?
        val
        {:base00 "#1a1b26"
         :base01 "#16161e"
         :base02 "#2f3549"
         :base03 "#444b6a"
         :base04 "#787c99"
         :base05 "#a9b1d6"
         :base06 "#cbccd1"
         :base07 "#d5d6db"
         :base08 "#c0caf5"
         :base09 "#a9b1d6"
         :base0A "#0db9d7"
         :base0B "#9ece6a"
         :base0C "#b4f9f8"
         :base0D "#2ac3de"
         :base0E "#bb9af7"
         :base0F "#f7768e"})))

(fn is_dark [_hex]
  (local hex (_hex:gsub "#" ""))
  (local r (tonumber (hex:sub 1 2) 16))
  (local g (tonumber (hex:sub 3 4) 16))
  (local b (tonumber (hex:sub 5 6) 16))
  (local brightness (+ (* 0.2126 r) (* 0.7152 g) (* 0.0722 b)))
  (< brightness 128))

(var IsTransparent false)

;; statusline and tabline set their own groups on ColorScheme
(fn apply_theme [base16]
  ((. (require :mini.base16) :setup) {:use_cterm true :palette base16})
  (set IsTransparent false)
  ;; fnlfmt: skip
  (vim.cmd (.. "hi LineNr guifg=" base16.base0E "\n"
               "hi LspInlayHint guifg=" base16.base04 "\n"))
  (each [group color (pairs base16)]
    (let [fg_color (if (is_dark color) "#ffffff" "#000000")]
      (vim.cmd (string.format "highlight GP_%s guifg=%s guibg=%s gui=NONE"
                              group fg_color color))))
  (vim.api.nvim_exec_autocmds :ColorScheme {}))

(apply_theme (get_base16))

;; home-manager swaps the style.lua symlink on every switch, which ends a
;; watch on the file itself, so watch the directory
(when vim.env.THEME_WATCH
  (local fse (vim.uv.new_fs_event))
  (vim.uv.fs_event_start fse stylix-dir {}
                         (vim.schedule_wrap (fn [err filename]
                                              (when (and (not err)
                                                         (= filename
                                                            :style.lua))
                                                (apply_theme (get_base16))
                                                (vim.notify "Switched Themes"
                                                            vim.log.levels.INFO)))))
  (vim.notify (.. "Now watching " stylix-dir
                  "/style.lua for external changes")
              vim.log.levels.INFO))


(fn set_hl [gp opt] (vim.api.nvim_set_hl 0 gp opt))

(fn ToggleBackground []
  (let [palette (. (. (require :mini.base16) :config) :palette)]
    (if IsTransparent
        (do
          (set_hl :Normal {:fg palette.base05 :bg palette.base00})
          (set_hl :LineNr {:fg palette.base0E :bg palette.base00})
          (set_hl :SignColumn {:fg palette.base03 :bg palette.base00})
          (set_hl :NonText {:fg palette.base02 :bg palette.base00})
          (set IsTransparent false))
        (do
          (set_hl :Normal {:bg :NONE})
          (set_hl :LineNr {:fg palette.base0E :bg :NONE})
          (set_hl :SignColumn {:fg palette.base03 :bg :NONE})
          (set_hl :NonText {:fg palette.base02 :bg :NONE})
          (set IsTransparent true)))))

(vim.keymap.set :n :<LEADER>bt ToggleBackground {:noremap true :silent true})
