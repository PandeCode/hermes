;; extends

(
  (comment) @injection.language
  .
  (multiline_string) @injection.content
  (#match? @injection.language "^//[ \t]*[A-Za-z0-9_+-]+$")
  (#gsub! @injection.language "^//[ \t]*" "")
  (#set! injection.combined)
)

; a fenced block in // or /// comments goes to the fence's language
;   /// ```wavedrom
;   /// { signal: [{ name: "clk", wave: "p...." }] }
;   /// ```
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

((comment) @injection.language
  .
  (comment)+ @injection.content
  .
  (comment) @_close
  (#lua-match? @injection.language "^///%s*```%w+%s*$")
  (#not-any-lua-match? @injection.content "^///%s*```")
  (#lua-match? @_close "^///%s*```%s*$")
  (#gsub! @injection.language "^///%s*```(%w+).*" "%1")
  (#offset! @injection.content 0 3 0 0))
