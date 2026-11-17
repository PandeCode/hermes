;; extends

; a one-word comment before a string names the string's language
;   (local code ; asm
;     "mov r0, #1")
((comment
  body: (comment_body) @injection.language)
  .
  (string
    content: (string_content) @injection.content)
  (#lua-match? @injection.language "^%s*[%w_+-]+%s*$")
  (#gsub! @injection.language "^%s*([%w_+-]+)%s*$" "%1"))
