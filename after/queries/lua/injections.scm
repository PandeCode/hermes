;; extends

; a fenced block inside a --[[ ]] comment goes to the fence's language
((comment) @injection.content
  (#lua-match? @injection.content "^%-%-%[=*%[")
  (#fence! @injection.content)
  (#set! injection.include-children))
