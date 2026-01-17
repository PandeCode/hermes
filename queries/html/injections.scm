; ;; inherits: html
; ;; extends
; ((script_element
;   (raw_text) @injection.content)
;  (#set! injection.language "javascript"))
;
; ((style_element
;   (raw_text) @injection.content)
;  (#set! injection.language "css"))
;
; (script_element
;   (start_tag
;     (attribute
;       (attribute_name)
;       (quoted_attribute_value
;         (attribute_value) @av
;         (#any-of?
;          @av
;          "x-shader/x-fragment"
;          "x-shader/x-vertex"
;          ))))
;   ((raw_text)
;    @injection.content
;    (#set! injection.language "glsl")
;    )
;   )
