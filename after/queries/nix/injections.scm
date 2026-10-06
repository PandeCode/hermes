;; extends
;; the home-manager path injections from https://github.com/calops/hmts.nvim/
;; need its hmts-path? predicate, which fails on nvim 0.11+ (captures are node
;; lists now); these two need nothing extra

; Strings with shebang expressions:
;   ''
;   #! /bin/lang
;   ''
(
  (indented_string_expression
    (string_fragment) @injection.language (#lua-match? @injection.language "^%s*#!")
  ) @injection.content
  (#gsub! @injection.language ".*#!.*env (%S+).*" "%1")
  (#gsub! @injection.language ".*#!%s*%S*/(%S+).*" "%1")
  (#set! injection.include-children)
  (#set! injection.combined)
)

; Explicit annotations in comments:
;   /* lang */ ''script''
; or:
;   # lang
;   ''script''
((comment) @injection.language
  .
  (_ (string_fragment) @injection.content)
  (#gsub! @injection.language "[/*#%s]" "")
  (#set! injection.combined)
)
