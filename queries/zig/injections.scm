; C
(
  (comment) @comment
  .
  (multiline_string) @injection.content
  (#match? @comment "^//[ \t]*c$")
  (#set! injection.language "c")
)

; JSON
(
  (comment) @comment
  .
  (multiline_string) @injection.content
  (#match? @comment "^//[ \t]*json$")
  (#set! injection.language "json")
)

; ASM
(
  (comment) @comment
  .
  (multiline_string) @injection.content
  (#match? @comment "^//[ \t]*asm$")
  (#set! injection.language "asm")
)

; GLSL
(
  (comment) @comment
  .
  (multiline_string) @injection.content
  (#match? @comment "^//[ \t]*glsl$")
  (#set! injection.language "glsl")
)

; WGSL
(
  (comment) @comment
  .
  (multiline_string) @injection.content
  (#match? @comment "^//[ \t]*wgsl$")
  (#set! injection.language "wgsl")
)
