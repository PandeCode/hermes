;; graphviz, wavedrom, svgbob, d2 and typst in ``` fences: in markdown, typst
;; raw blocks and comments they get their language's highlighting, and K on
;; one shows it rendered. the renderers come with hermes
;;
;;   // ```wavedrom
;;   // { signal: [{ name: "clk", wave: "p...." }] }
;;   // ```

(local khover (require :khover))

;; the names a fence can use for each parser
(vim.treesitter.language.register :dot [:graphviz])
(vim.treesitter.language.register :json5 [:wavedrom])

;; the text before ``` (a comment marker, an indent) and the language
(fn opener [line]
  (line:match "^([^`]*)```(%w+)%s*$"))

(fn closer? [line]
  (not= nil (line:match "^[^`%w]*```[^`%w]*$")))

;; the rows of the fence lines around row, nil when row is not in a fence.
;; lines holds the rows from first on
(fn fence-around [lines first row]
  (let [at #(. lines (+ (- $1 first) 1))]
    (var open nil)
    (var close nil)
    ;; a closing fence above the cursor means it is past that block
    (var past false)
    (var r row)
    (while (and (= open nil) (not past) (at r))
      (if (opener (at r)) (set open r)
          (and (closer? (at r)) (not= r row)) (set past true))
      (set r (- r 1)))
    (when open
      (set r (+ open 1))
      (while (and (= close nil) (at r) (not (opener (at r))))
        (when (closer? (at r)) (set close r))
        (set r (+ r 1))))
    (when (and open close (<= row close))
      (values open close))))

;; how far K looks up and down for the fence lines
(local reach 500)

;; text for khover: the body of the fence around the cursor without the
;; comment marker the opener has, when its language is one of langs
(fn find [langs]
  (fn [buf row _]
    (let [first (math.max 0 (- row reach))
          lines (vim.api.nvim_buf_get_lines buf first (+ row reach) false)
          (open close) (fence-around lines first row)]
      (when open
        (let [(prefix lang) (opener (. lines (+ (- open first) 1)))
              bare (vim.trim prefix)
              body (icollect [_ line (ipairs (vim.list_slice lines
                                                             (+ (- open first)
                                                                2)
                                                             (- close first)))]
                     (if (vim.startswith line prefix)
                         (line:sub (+ (length prefix) 1))
                         (and (not= bare "") (vim.startswith line bare))
                         (line:sub (+ (length bare) 1))
                         line))]
          (when (vim.tbl_contains langs lang)
            (table.concat body "\n")))))))

;; (#fence! @capture) on a comment holding a whole fence, /* ``` ... ``` */:
;; the capture becomes the lines between the fence lines, in their language
(vim.treesitter.query.add_directive :fence!
                                    (fn [captures _ source pred metadata]
                                      (let [id (. pred 2)
                                            node (. captures id 1)
                                            row (node:start)
                                            lines (vim.split (vim.treesitter.get_node_text node
                                                                                           source)
                                                             "\n")]
                                        (var open nil)
                                        (each [i line (ipairs lines) &until open]
                                          (when (opener line) (set open i)))
                                        (when open
                                          (let [(open close) (fence-around lines
                                                                           1
                                                                           (+ open
                                                                              1))]
                                            ;; an empty range would mean the whole buffer
                                            (when (and open
                                                       (> close (+ open 1)))
                                              (let [(_ lang) (opener (. lines
                                                                        open))]
                                                (tset metadata
                                                      :injection.language lang)
                                                (tset metadata id
                                                      {:range [(+ row open)
                                                               0
                                                               (+ row close -1)
                                                               0]})))))))
                                    {:force true})

(fn color [name attr]
  (let [hl (vim.api.nvim_get_hl 0 {: name :link false})]
    (when (. hl attr)
      (string.format "#%06x" (. hl attr)))))

(fn fg []
  (or (color :Normal :fg) "#ffffff"))

;; dot draws in black unless told otherwise; colors set in the graph still win
(fn dot []
  (let [c (fg)]
    [:dot
     :-Tsvg
     :-Gbgcolor=transparent
     (.. :-Gcolor= c)
     (.. :-Gfontcolor= c)
     (.. :-Ncolor= c)
     (.. :-Nfontcolor= c)
     (.. :-Ecolor= c)
     (.. :-Efontcolor= c)]))

;; wavedrom-rs' dark skin with the float's colors, the light default is fine
;; on a light background
(fn wavedrom []
  (if (= vim.o.background :light)
      [:wavedrom]
      (let [bg (or (color :NormalFloat :bg) (color :Normal :bg) "#222222")
            text (fg)
            hint (or (color :Comment :fg) "#555555")
            skin (string.format "{
  background: %q,
  undefined_background: %q,
  backgrounds: [%q, \"#0C759D\", \"#328640\", \"#9D2D0C\", \"#3C4D9F\", \"#13600B\", \"#9F3C60\", \"#903C9F\"],
  header: { color: %q, cycle_marker_color: %q },
  footer: { color: %q, cycle_marker_color: %q },
  signal: {
    marker_color: %q, name_color: %q, path_color: %q, gap_color: %q,
    gap_background_color: %q, hint_line_color: %q, undefined_color: %q,
    group_indicator: { color: %q, label_color: %q },
    edge: {
      node_text_color: %q, node_background_color: %q,
      edge_text_color: %q, edge_text_background_color: %q,
      edge_color: %q, edge_arrow_color: %q,
    },
  },
}" bg bg bg text text text text text text text
                                text bg hint text text text text bg text bg text
                                text)
            path (.. (vim.fn.stdpath :cache) :/khover/wavedrom-
                     (vim.fn.sha256 skin) :.json5)]
        (when (not (vim.uv.fs_stat path))
          (vim.fn.mkdir (vim.fs.dirname path) :p)
          (vim.fn.writefile (vim.split skin "\n") path))
        [:wavedrom :-s path])))

;; ascii art, as in a comment
(fn svgbob []
  (let [c (fg)]
    [:svgbob :--background :transparent :--stroke-color c :--fill-color c]))

;; d2 draws its own background, so its dark or light theme follows nvim's
(fn d2 []
  [:d2 :--theme (if (= vim.o.background :light) :0 :200) :--pad :8 "-" "-"])

(khover.register {:filetype "*"
                  :find (find [:svgbob :bob])
                  :cmd svgbob
                  :kind :svg})

(khover.register {:filetype "*" :find (find [:d2]) :cmd d2 :kind :svg})

(khover.register {:filetype "*"
                  :find (find [:graphviz :dot])
                  :cmd dot
                  :kind :svg})

(khover.register {:filetype "*"
                  :find (find [:wavedrom])
                  :cmd wavedrom
                  :kind :svg})

(khover.register {:filetype "*" :find (find [:typst]) :kind :typst_doc})
