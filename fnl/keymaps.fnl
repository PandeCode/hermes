(set vim.g.mapleader " ")
(set vim.g.maplocalleader "\\")

(macro defset [m ms]
  `(fn ,m
     [a# b# c#]
     (vim.keymap.set ,ms a# b# c#)))

(defset n :n)
(defset c :c)
(defset v :v)
(defset i :i)
(defset x :x)
(defset a "")

(macro cmd [v] (.. :<cmd> v :<cr>))
(macro leader [v] (.. :<leader> v))

(local silent {:silent true})
(local noremap {:noremap true})
(local noremap_expr {:noremap true :expr true})
(local noremap_silent {:silent true :noremap true})

(do
  (n :<esc> (cmd :nohlsearch))
  (n (leader :fe) (fn [] (vim.cmd.edit "%") (vim.treesitter.start)))
  (n (leader :fs) (cmd :w))
  (n (leader :sf) (cmd "source %"))
  (n (leader :fw) (cmd "noautocmd w"))
  (n (leader :li) (cmd :LspInfo) noremap_silent)
  (n (leader :lq) (cmd :LspStop) noremap_silent)
  (n (leader :lr) (cmd :LspRestart) noremap_silent)
  (n (leader :ls) (cmd :LspStart) noremap_silent)
  (n (leader :me) vim.cmd.messages nil)
  (n (leader :bp) vim.cmd.bp noremap_silent)
  (n (leader :bn) vim.cmd.bn noremap_silent)
  (n (leader :bo) (cmd "%bd|e#") noremap_silent)
  (n :<A-d> vim.cmd.bd noremap_silent)
  (n (leader :c<leader>) (cmd "normal gcc") noremap_silent)
  (v (leader :c<leader>) :gc noremap_silent)
  (n (leader "`") (cmd "e#") noremap_silent)
  (n (leader :gf) (cmd "e <cfile>"))
  (n (leader :<F2>) ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/g<Left><Left>")
  (x :I (fn []
          (if (= (vim.fn.mode) :V) :^<C-v>I :I)) {:expr true})
  (x :A (fn []
          (if (= (vim.fn.mode) :V) :$<C-v>A :A)) {:expr true})
  (n :Q "")
  ;; Disable visual mode
  (n :<Home> "(col('.') == matchend(getline('.'), '^\\s*')+1 ? '0' : '^')"
     noremap_expr)
  (n :<End> "(col('.') == match(getline('.'), '\\s*$') ? '$' : 'g_')"
     noremap_expr)
  (v :<End> "(col('.') == match(getline('.'), '\\s*$') ? '$h' : 'g_')"
     noremap_expr)
  (i :<Home> :<C-o><Home>)
  (i "<End> " :<C-o><End>)
  (n :gg :gg0 noremap)
  (a :G :G<End> noremap)
  (a :Y :y$ noremap)
  (n (leader :w) :<c-w> noremap)
  (n (leader :w|) (cmd :vsplit) noremap)
  (n (leader :w_) (cmd :split) noremap)
  (n (leader :j) ":<c-u>put!=repeat([''],v:count)<bar>']+1<cr>" noremap_silent)
  (n (leader :k) ":<c-u>put =repeat([''],v:count)<bar>'[-1<cr>" noremap_silent)
  ;; system clipboard
  (n :<c-c> "\"+y\"" noremap)
  (v :<c-c> "\"+y\"" noremap)
  (n :<c-v> "\"+p\"" noremap)
  (i :<c-v> :<c-r>+ noremap)
  (c :<c-v> :<c-r>+ noremap)
  (n :<c-x> :<c-c>d)
  (i :<c-x> :<c-c>d)
  (c :<c-x> :<c-c>d)
  ;; use <c-r> to insert original character without triggering things like auto-pairs
  (i :<c-r> :<c-v> noremap)
  (n :n :nzzzv noremap)
  (n :N :Nzzzv noremap)
  (n :J "mzJ`z" noremap)
  (i "," ",<c-g>u" noremap)
  (i "." :.<c-g>u noremap)
  (i "!" :!<c-g>u noremap)
  (i "?" :?<c-g>u noremap)
  (i "[" "[<c-g>u" noremap)
  (i "]" "]<c-g>u" noremap)
  (i "(" "(<c-g>u" noremap)
  (i ")" ")<c-g>u" noremap)
  (i "{" "{<c-g>u" noremap)
  (i "}" "}<c-g>u" noremap)
  (i "\"" "\"<c-g>u" noremap)
  (n "<" :v<gv<ESC> noremap)
  (n ">" :v>gv<ESC> noremap)
  (v "<" :<gv noremap)
  (v ">" :>gv noremap)
  (v "`" "<ESC>`>a`<ESC>`<i`<ESC>" noremap)
  (v "(" "<ESC>`>a)<ESC>`<i(<ESC>" noremap)
  (v "'" "<ESC>`>a'<ESC>`<i'<ESC>" noremap)
  (v "<c-{>" "<ESC>`>a}<ESC>`<i{<ESC>" noremap)
  (v ")" "<ESC>`>a)<ESC>`<i(<ESC>" noremap)
  (v "]" "<ESC>`>a]<ESC>`<i[<ESC>" noremap)
  (v "<c-}>" "<ESC>`>a}<ESC>`<i{<ESC>" noremap)
  (x "/" "<Esc>/\\%V")
  (i :<c-f> "<c-g>u<Esc>[s1z=gi<c-g>u" noremap)
  (n (leader :tt) (fn []
                    (if (or (= vim.g.showtabline nil) (= vim.g.showtabline 2))
                        (do
                          (set vim.g.showtabline 0)
                          (vim.cmd "set showtabline=0"))
                        (do
                          (set vim.g.showtabline 2)
                          (vim.cmd "set showtabline=2"))))
     noremap))

; noremap Y "+y
; nnoremap YY "+yy
; nnoremap / /\v
; vnoremap / /\v
;
; cnoremap w!! execute 'silent! write !sudo tee % >/dev/null' <bar> edit!

nil
