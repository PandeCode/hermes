;; extends

(
  (comment) @injection.language
  .
  (multiline_string) @injection.content
  (#match? @injection.language "^//[ \t]*[A-Za-z0-9_+-]+$")
  (#gsub! @injection.language "^//[ \t]*" "")
  (#set! injection.combined)
)
