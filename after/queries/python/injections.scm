;; extends

; a one-word comment names the language of the string after it, inside
; brackets or on the line above an assignment
;   cur.execute(  # sql
;       "select 1")
;
;   # sql
;   query = """
;   select 1
;   """
((comment) @injection.language
  .
  (string
    [
      (string_content) @injection.content
      (interpolation)
    ]+)
  (#lua-match? @injection.language "^#%s*[%w_+-]+%s*$")
  (#gsub! @injection.language "^#%s*([%w_+-]+).*" "%1"))

((comment) @injection.language
  .
  (expression_statement
    (assignment
      right: (string
        [
          (string_content) @injection.content
          (interpolation)
        ]+)))
  (#lua-match? @injection.language "^#%s*[%w_+-]+%s*$")
  (#gsub! @injection.language "^#%s*([%w_+-]+).*" "%1"))
