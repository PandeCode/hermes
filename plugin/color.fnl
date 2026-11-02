;; colors in code: rgb(), rgba(), vec3(), vec4() and 0xRRGGBB get their color
;; as background like #RRGGBB does, K on one shows a swatch and K again
;; opens ccc's picker, which writes the color back in the same notation
;;
;;   vec3(1.0, 0.5, 0.0)   vec4(0.2, 0.4, 0.6, 1.0)   rgb(255 128 0)   0xff8000

(local ccc (require :ccc))
(local khover (require :khover))

;; what each notation looks like, its reader decides whether it is a color
(local shapes {:hex "#%x+"
               :num "%f[%w]0[xX]%x+"
               :rgb "%f[%w]rgba?%b()"
               :hsl "%f[%w]hsla?%b()"
               :vec "%f[%w]vec[34]%s*%b()"})

;; the first match of shape in s from init that read turns into
;; [rgb alpha], as start stop rgb alpha
(fn scan [s shape init read]
  (var from (or init 1))
  (var found nil)
  (while (and from (not found))
    (let [(start stop) (s:find shape from)]
      (if (not start) (set from nil)
          (let [color (read (s:sub start stop))]
            (if color
                (set found [start stop (unpack color 1 2)])
                (set from (+ stop 1)))))))
  (when found
    (unpack found 1 4)))

;; 0.5, .5, 1., 1 and glsl's 0.5f
(fn unit [s]
  (let [digits (: (vim.trim s) :gsub "[fF]$" "")
        n (tonumber digits)]
    (when (and n (>= n 0) (<= n 1))
      n)))

;; vec3(r, g, b), vec4(r, g, b, a) and vec3(0.5), a gray
(fn read-vec [size]
  (fn [text]
    (let [args (text:match (.. :^vec size "%s*%((.*)%)$"))
          parts (if args (vim.split args "," {:plain true}) [])
          nums (icollect [_ p (ipairs parts)] (unit p))]
      (when (and args (= (length parts) (length nums)))
        (if (= (length nums) 1)
            (let [n (. nums 1)]
              [[n n n] (when (= size 4) n)])
            (= (length nums) size)
            [[(. nums 1) (. nums 2) (. nums 3)] (. nums 4)])))))

;; 0xRRGGBB, as c and zig write a color
(fn read-num [text]
  (let [hex (text:match "^0[xX](%x%x%x%x%x%x)$")]
    (when hex
      [(icollect [byte (hex:gmatch "%x%x")]
         (/ (tonumber byte 16) 255))])))

;; one of ccc's own pickers, when it reads all of text. ccc's css pickers
;; try their patterns one after another over the whole line, so with
;; rgb(1, 2, 3) and rgb(1 2 3) on one line the first one is never found
(fn read-ccc [picker]
  (fn [text]
    (let [(start stop rgb alpha) (picker:parse_color text 1)]
      (when (and start (= start 1) (= stop (length text)))
        [rgb alpha]))))

(fn picker [shape read]
  {:parse_color (fn [_ s init] (scan s shape init read))})

(fn byte [n]
  (math.floor (+ (* n 255) 0.5)))

(fn decimal [n]
  (let [s (: (string.format "%.3f" n) :gsub :0+$ "")]
    (if (vim.endswith s ".") (.. s :0) s)))

(fn vec-output [size]
  {:name (.. :vec size)
   :str (fn [[r g b] a]
          (let [parts (icollect [_ n (ipairs [r g b (when (= size 4) (or a 1))])]
                        (decimal n))]
            (.. :vec size "(" (table.concat parts ", ") ")")))})

(local num-output {:name :0xRRGGBB
                   :str (fn [[r g b]]
                          (string.format "0x%02x%02x%02x" (byte r) (byte g)
                                         (byte b)))})

;; ccc writes css' rgb(1 2 3 / 100%), code mostly calls rgb(1, 2, 3)
(local rgb-output
       {:name :rgb
        :str (fn [[r g b] a]
               (if (and a (< a 1))
                   (string.format "rgba(%d, %d, %d, %s)" (byte r) (byte g)
                                  (byte b) (decimal a))
                   (string.format "rgb(%d, %d, %d)" (byte r) (byte g) (byte b))))})

(local vec3-output (vec-output 3))

;; each notation: how it is read and how a picked color is written back
(local notations
       [[shapes.hex (read-ccc ccc.picker.hex) ccc.input.rgb ccc.output.hex]
        [shapes.rgb (read-ccc ccc.picker.css_rgb) ccc.input.rgb rgb-output]
        [shapes.hsl
         (read-ccc ccc.picker.css_hsl)
         ccc.input.hsl
         ccc.output.css_hsl]
        ["%f[%w]vec3%s*%b()" (read-vec 3) ccc.input.rgb vec3-output]
        ["%f[%w]vec4%s*%b()" (read-vec 4) ccc.input.rgb (vec-output 4)]
        [shapes.num read-num ccc.input.rgb num-output]])

(local pickers (icollect [_ [shape read] (ipairs notations)]
                 (picker shape read)))

(ccc.setup {: pickers
            :outputs (icollect [_ [_ _ _ output] (ipairs notations)] output)
            :recognize {:input true
                        :output true
                        :pattern (collect [i [_ _ input output] (ipairs notations)]
                                   (values (. pickers i) [input output]))}})

;; [rgb alpha] of text, read by the first notation that reads all of it
(fn read [text]
  (var found nil)
  (each [_ [_ read-one] (ipairs notations) &until found]
    (set found (read-one text)))
  found)

(fn to-hex [[r g b]]
  (string.format "#%02x%02x%02x" (byte r) (byte g) (byte b)))

;; mini.hipatterns reads its config on every redraw, so these join the
;; highlighters plugins.fnl set up. hex and 0x ones are there already
(fn highlighter [pattern]
  {: pattern
   :group (fn [_ text]
            (let [color (read text)]
              (when color
                (MiniHipatterns.compute_hex_color_group (to-hex (. color 1))
                                                        :bg))))
   :extmark_opts {:priority 200}})

(set MiniHipatterns.config.highlighters.css_rgb (highlighter shapes.rgb))
(set MiniHipatterns.config.highlighters.vec (highlighter shapes.vec))

;; the color text under the cursor. 0x numbers are left to number.fnl,
;; which shows a 0xRRGGBB's color with the rest
(fn find [buf row col]
  (khover.match_at buf row col [shapes.hex shapes.rgb shapes.hsl shapes.vec]
                   read))

(var swatch-win nil)

;; K shows the color and its other notations, K on it again picks a new one
(fn show [text]
  (if (and swatch-win (vim.api.nvim_win_is_valid swatch-win))
      (do
        (vim.api.nvim_win_close swatch-win true)
        (set swatch-win nil)
        (vim.cmd.CccPick))
      (let [[rgb a] (read text)
            hex (to-hex rgb)
            pad "        "
            forms [hex
                   (rgb-output.str rgb a)
                   (vec3-output.str rgb)
                   (num-output.str rgb)]
            lines (doto (icollect [_ form (ipairs forms)]
                          (.. pad " " form))
                    (table.insert "K again to pick"))
            (buf win) (vim.lsp.util.open_floating_preview lines ""
                                                          {:border :rounded
                                                           :focus_id :khover
                                                           :close_events [:CursorMoved
                                                                          :CursorMovedI
                                                                          :InsertEnter
                                                                          :BufLeave]})
            ns (vim.api.nvim_create_namespace :color-swatch)]
        (vim.api.nvim_set_hl 0 :ColorSwatch {:bg hex})
        (for [row 0 (- (length forms) 1)]
          (vim.api.nvim_buf_set_extmark buf ns row 0
                                        {:end_col (length pad)
                                         :hl_group :ColorSwatch}))
        (vim.api.nvim_buf_set_extmark buf ns (length forms) 0
                                      {:end_col 15 :hl_group :Comment})
        (set swatch-win win))))

(khover.register {:filetype "*" : find :kind show})
