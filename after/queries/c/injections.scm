;; extends

; a fenced block in // comments goes to the fence's language
;   // ```graphviz
;   // a -> b
;   // ```
((comment) @injection.language
  .
  (comment)+ @injection.content
  .
  (comment) @_close
  (#lua-match? @injection.language "^//%s*```%w+%s*$")
  (#not-any-lua-match? @injection.content "^//%s*```")
  (#lua-match? @_close "^//%s*```%s*$")
  (#gsub! @injection.language "^//%s*```(%w+).*" "%1")
  (#offset! @injection.content 0 2 0 0))

; and one inside a /* */ comment
((comment) @injection.content
  (#lua-match? @injection.content "^/%*")
  (#fence! @injection.content)
  (#set! injection.include-children))

; a one-word comment before a string names the string's language
;   static const char *vs = // glsl
;       "#version 330 core\n"
;       "void main() {}\n";
((comment) @injection.language
  .
  [
    (string_literal) @injection.content
    (concatenated_string
      (string_literal) @injection.content)
  ]
  (#lua-match? @injection.language "^/[/*]%s*[%w_+-]+%s*[*/]*$")
  (#gsub! @injection.language "^/[/*]%s*([%w_+-]+).*" "%1")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.include-children))
