;; K on 0x, 0b or 0o number shows it in decimal, hex, octal and binary. the
;; _ and ' digit separators of zig and c++ and c's u/l suffixes are fine,
;; 0xRRGGBB also gets its color
;;
;;   0xff   0b1010_0101   0o755   0x4002_0C8CUL

(local ffi (require :ffi))
(local khover (require :khover))

(local bases {:x 16 :b 2 :o 8})

;; digits past these do not fit 64 bits
(local widths {16 16 2 64 8 22})

;; the number as a uint64 and its base and digits, nil for anything else
(fn read [text]
  (let [(kind body) (text:match "^0([xXbBoO])([%x_']+)[uUlLzZ]*$")
        base (when kind (. bases (kind:lower)))
        digits (when base (body:gsub "[_']" ""))]
    (when (and digits (not= digits "") (<= (length digits) (. widths base)))
      (var n (ffi.new :uint64_t 0))
      (var ok true)
      (each [d (digits:gmatch ".")]
        (let [v (tonumber d 16)]
          (if (< v base) (set n (+ (* n base) v)) (set ok false))))
      (when ok
        (values n base digits)))))

;; n written in base
(fn digits-of [n base]
  (var left n)
  (local out [])
  (while (> left 0)
    (table.insert out 1 (string.format "%x" (tonumber (% left base))))
    (set left (/ left base)))
  (if (= (length out) 0) :0 (table.concat out)))

;; s in groups of four digits from the right, as 1111 0000. pad fills the
;; first group with zeros
(fn group [s sep pad]
  (let [short (% (length s) 4)
        s (if (and pad (> short 0)) (.. (string.rep :0 (- 4 short)) s) s)
        first (if (or pad (= short 0)) 4 short)
        rest (fcollect [i (+ first 1) (length s) 4]
               (s:sub i (+ i 3)))]
    (table.concat [(s:sub 1 first) (unpack rest)] sep)))

(fn find [buf row col]
  (khover.match_at buf row col ["%f[%w]0[xXbBoO][%x_']+[uUlLzZ]*%f[^%w]"] read))

(fn show [text]
  (let [(n base digits) (read text)
        bin (digits-of n 2)
        lines [(.. "dec  " (: (tostring n) :gsub :ULL$ ""))
               (.. "hex  0x" (group (digits-of n 16) "_"))
               (.. "oct  0o" (digits-of n 8))
               (.. "bin  " (group bin " " true)
                   (if (= n 0) "" (.. "  (" (length bin) " bits)")))]
        color (when (and (= base 16) (= (length digits) 6))
                (.. "#" (digits:lower)))]
    (when color
      (table.insert lines (.. "         " color)))
    (let [(buf) (vim.lsp.util.open_floating_preview lines ""
                                                    {:border :rounded
                                                     :focus_id :khover
                                                     :close_events [:CursorMoved
                                                                    :CursorMovedI
                                                                    :InsertEnter
                                                                    :BufLeave]})
          ns (vim.api.nvim_create_namespace :number-hover)]
      (for [row 0 3]
        (vim.api.nvim_buf_set_extmark buf ns row 0
                                      {:end_col 3 :hl_group :Comment}))
      (when color
        (vim.api.nvim_set_hl 0 :NumberSwatch {:bg color})
        (vim.api.nvim_buf_set_extmark buf ns 4 0
                                      {:end_col 8 :hl_group :NumberSwatch})))))

(khover.register {:filetype "*" : find :kind show})
