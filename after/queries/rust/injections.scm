;; extends

; a fenced block inside a /* */ comment goes to the fence's language
((block_comment) @injection.content
  (#fence! @injection.content)
  (#set! injection.include-children))

; a one-word comment before a string names the string's language
;   const SHADER: &str = // wgsl
;       r#"fn main() {}"#;
(([
  (line_comment)
  (block_comment)
] @injection.language
  .
  (raw_string_literal
    (string_content) @injection.content))
  (#lua-match? @injection.language "^/[/*]%s*[%w_+-]+%s*[*/]*$")
  (#gsub! @injection.language "^/[/*]%s*([%w_+-]+).*" "%1"))

; a plain string keeps its escapes, the language sees them as they are
;   let q = /* sql */ "select a\nfrom t";
(([
  (line_comment)
  (block_comment)
] @injection.language
  .
  (string_literal) @injection.content)
  (#lua-match? @injection.language "^/[/*]%s*[%w_+-]+%s*[*/]*$")
  (#gsub! @injection.language "^/[/*]%s*([%w_+-]+).*" "%1")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.include-children))
