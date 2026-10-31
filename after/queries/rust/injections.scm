;; extends

; a fenced block inside a /* */ comment goes to the fence's language
((block_comment) @injection.content
  (#fence! @injection.content)
  (#set! injection.include-children))
