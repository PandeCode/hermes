;; extends

; a fenced block inside a --[[ ]] comment goes to the fence's language
((comment) @injection.content
  (#lua-match? @injection.content "^%-%-%[=*%[")
  (#fence! @injection.content)
  (#set! injection.include-children))

; a one-word comment before a string names the string's language
;   local vs = -- glsl
;     [[ void main() { } ]]
((comment
  content: (_) @injection.language)
  .
  (expression_list
    .
    (string
      content: (_) @injection.content))
  (#lua-match? @injection.language "^%s*[%w_+-]+%s*$")
  (#gsub! @injection.language "^%s*([%w_+-]+)%s*$" "%1"))

; the same in a call or a table field, where no expression_list wraps it
;   f(-- glsl
;     [[ void main() { } ]])
((comment
  content: (_) @injection.language)
  .
  (string
    content: (_) @injection.content)
  (#lua-match? @injection.language "^%s*[%w_+-]+%s*$")
  (#gsub! @injection.language "^%s*([%w_+-]+)%s*$" "%1"))
