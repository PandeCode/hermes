;; inherits: html
;; extends
(_
  (comment) @c
  (#any-of? @c "// json" "//json")
  [
   (string
     ((string_content) @injection.content
                       (#set! injection.language "json"))
     )
   ((multiline_string) @injection.content
                       (#set! injection.language "json"))
   ]
  )


(_
  (comment) @c
  (#any-of? @c "// wgsl" "//wgsl")
   ((multiline_string) @injection.content
                       (#set! injection.language "wgsl")))

(_
  (comment) @c
  (#any-of? @c "// wgsl" "//wgsl")
   ((multiline_string) @injection.content
                       (#set! injection.language "wgsl"))
)
)

(
 (comment) @c
 (#any-of? @c "// json" "//json")
 [
  (expression_statement
    (call_expression
      arguments:
      (arguments
        (string
          ((string_content)
           @injection.content
           (#set! injection.language "json")
           )
          ))))
  (variable_declaration
    (string
      ((string_content) @injection.content
                        (#set! injection.language "json"))
      ))
  ]
 )
