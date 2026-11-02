;; gK on a register of an mcu shows its bit fields from the chip's svd: a name
;; like RCC_AHB2ENR, RCC->AHB2ENR or RCC.AHB2ENR, an address like 0x44020C8C,
;; or a peripheral name for its list of registers. the svd is vim.g.svd, or
;; the first *.svd in a .pyocd folder above the file (pyocd's pack layout)

(local khover (require :khover))

(fn tag [xml name]
  (xml:match (.. "<" name ">%s*(.-)%s*</" name ">")))

(fn number [s]
  (when s
    (tonumber (if (s:match "^0[xX]") (s:sub 3) s)
              (if (s:match "^0[xX]") 16 10))))

(fn clean [s]
  (when s
    (: (s:gsub "%s+" " ") :gsub "^ " "")))

(fn parse-register [xml]
  {:name (tag xml :name)
   :description (clean (tag xml :description))
   :offset (number (tag xml :addressOffset))
   :access (tag xml :access)
   :reset (tag xml :resetValue)
   :fields (icollect [field (xml:gmatch "<field>(.-)</field>")]
             {:name (tag field :name)
              :description (clean (tag field :description))
              :offset (number (tag field :bitOffset))
              :width (number (tag field :bitWidth))})})

;; enumerated values are most of a big svd and nothing here shows them
(fn parse [text]
  (let [text (text:gsub :<enumeratedValues>.-</enumeratedValues> "")
        peripherals []
        by-name {}]
    (each [attrs body (text:gmatch "<peripheral([^>]*)>(.-)</peripheral>")]
      (let [head (or (body:match "^(.-)<registers>") body)
            p {:name (tag head :name)
               :description (clean (tag head :description))
               :base (number (tag head :baseAddress))
               :derived (attrs:match "derivedFrom=\"([^\"]+)\"")
               :registers (icollect [reg (body:gmatch "<register>(.-)</register>")]
                            (parse-register reg))}]
        (table.insert peripherals p)
        (tset by-name p.name p)))
    ;; a derived peripheral only names its base address
    (each [_ p (ipairs peripherals)]
      (when (and p.derived (= 0 (length p.registers)) (. by-name p.derived))
        (set p.registers (. by-name p.derived :registers))
        (set p.description
             (or p.description (. by-name p.derived :description)))))
    {: peripherals : by-name}))

(local cache {})

(fn load [path]
  (let [mtime (. (vim.uv.fs_stat path) :mtime :sec)
        hit (. cache path)]
    (if (and hit (= hit.mtime mtime))
        hit.svd
        (let [svd (parse (table.concat (vim.fn.readfile path) "\n"))]
          (tset cache path {: mtime : svd})
          svd))))

(fn svd-path [buf]
  (or vim.g.svd
      (let [root (vim.fs.root buf :.pyocd)]
        (when root
          (. (vim.fn.glob (.. root :/.pyocd/*.svd) false true) 1)))))

;; the register of peripheral p called name, with or without p's prefix
(fn register [p name]
  (var found nil)
  (each [_ r (ipairs p.registers) &until found]
    (when (or (= r.name name) (= r.name (.. p.name "_" name))
              (= (r.name:gsub "^[%w]+_" "") name))
      (set found r)))
  found)

(fn lookup [svd text]
  (let [(pname rname) (text:match "^([%w_]+)%s*[%-%.]>?%s*([%w_]+)$")
        address (when (text:match "^0[xX]%x+$") (number text))]
    (var found nil)
    (if pname
        (let [p (. svd.by-name pname)
              r (and p (register p rname))]
          (when r (set found {: p : r})))
        address
        (each [_ p (ipairs svd.peripherals) &until found]
          (if (= p.base address) (set found {: p})
              (each [_ r (ipairs p.registers) &until found]
                (when (= (+ p.base r.offset) address)
                  (set found {: p : r})))))
        (. svd.by-name text)
        (set found {:p (. svd.by-name text)})
        (each [_ p (ipairs svd.peripherals) &until found]
          (each [_ r (ipairs p.registers) &until found]
            (when (= r.name text)
              (set found {: p : r})))))
    found))

;; the text under the cursor: a.b, a->b, a word or a number
(fn find-text [buf row col]
  (khover.match_at buf row col ["[%w_]+%s*%->%s*[%w_]+"
                                "[%w_]+%.[%w_]+"
                                "0[xX]%x+"
                                "[%w_]+"]))

;; typst source, as a string literal so svd text can't be read as markup
(fn str [s]
  (.. "#\"" (: (: (or s "") :gsub "\\" "\\\\") :gsub "\"" "\\\"") "\""))

(fn hex [n]
  (string.format "0x%08X" n))

(fn register-doc [p r]
  (let [fields (doto (vim.deepcopy r.fields)
                 (table.sort #(> $1.offset $2.offset)))
        cells []]
    ;; fields from bit 31 down, the bits no field has are left shaded
    (var bit 31)
    (each [_ f (ipairs fields)]
      (let [top (+ f.offset f.width -1)]
        (when (> bit top)
          (table.insert cells
                        (string.format "table.cell(colspan: %d, fill: gray.transparentize(80%%))[]"
                                       (- bit top))))
        ;; a bit is about two letters wide, longer names stand up
        (table.insert cells
                      (string.format (if (> (length f.name) (* f.width 2))
                                         "table.cell(colspan: %d)[#rotate(-90deg, reflow: true)[%s]]"
                                         "table.cell(colspan: %d)[%s]")
                                     f.width (str f.name)))
        (set bit (- f.offset 1))))
    (when (>= bit 0)
      (table.insert cells (string.format "table.cell(colspan: %d, fill: gray.transparentize(80%%))[]"
                                         (+ bit 1))))
    (table.concat [(.. "*" (str r.name) "* #h(1em) `" (hex (+ p.base r.offset))
                       "` #h(1em) " (str (or r.access "")) " #h(1em) reset `"
                       (or r.reset "?") "`")
                   ""
                   (str r.description)
                   ""
                   "#set text(size: 8pt)"
                   "#table(columns: (1.6em,) * 32, align: center + horizon, inset: 2pt, stroke: none,"
                   "  ..range(31, -1, step: -1).map(i => [#i]))"
                   "#v(-1em)"
                   (.. "#context table(columns: (1.6em,) * 32, align: center + horizon, inset: 2pt, stroke: text.fill,
  " (table.concat cells ",\n  ") ")")
                   "#table(columns: 3, stroke: none, inset: 2pt,"
                   (table.concat (icollect [_ f (ipairs fields)]
                                   (string.format "  [%s], [*%s*], [%s],"
                                                  (if (= f.width 1)
                                                      (tostring f.offset)
                                                      (.. (+ f.offset f.width
                                                             -1)
                                                          ":" f.offset))
                                                  (str f.name)
                                                  (str f.description)))
                                 "\n")
                   ")"] "\n")))

(fn peripheral-doc [p]
  (table.concat [(.. "*" (str p.name) "* #h(1em) `" (hex p.base) "`")
                 ""
                 (str p.description)
                 ""
                 "#set text(size: 8pt)"
                 "#table(columns: 3, stroke: none, inset: 2pt,"
                 (table.concat (icollect [_ r (ipairs p.registers)]
                                 (string.format "  [`+0x%03X`], [*%s*], [%s],"
                                                r.offset (str r.name)
                                                (str r.description)))
                               "\n")
                 ")"] "\n"))

(fn find [buf row col]
  (let [path (svd-path buf)
        text (when path (find-text buf row col))
        hit (when text (lookup (load path) text))]
    (when hit
      (if hit.r (register-doc hit.p hit.r) (peripheral-doc hit.p)))))

(khover.register {:filetype [:c :cpp :zig :rust :asm]
                  :key :gK
                  : find
                  :kind :typst_doc})
