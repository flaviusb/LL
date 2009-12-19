(= json-true  (match-literal "true"  t))
(= json-false (match-literal "false" nil))
(= json-null  (match-literal "null"  nil))

(= json-number-char
  (match [find _ ".-+eE1234567890"]))

(= json-number
  (with-result cs (many1 json-number-char)
    (coerce (string cs) 'num)))

(def hexdigit (c)
  (and (isa c 'char)
       (or (<= #\a c #\f) (<= #\A c #\F) (<= #\0 c #\9))))

(= fourhex
  (must "four hex digits required after \\u"  
    (with-seq (h1 (match hexdigit)
               h2 (match hexdigit)
               h3 (match hexdigit)
               h4 (match hexdigit))
      (coerce (int (coerce (list h1 h2 h3 h4) 'string) 16) 'char))))

(def json-backslash-char (c)
  (case c
    #\" #\"
    #\\ #\\
    #\/ #\/
    #\b #\backspace
    #\f #\page
    #\n #\newline
    #\r #\return
    #\t #\tab
    (err "invalid backslash char" c)))

(= json-backslash-escape
  (seq2 (match-is #\\)
        (alt (seq2 (match-is #\u)
                   fourhex)
             (fn (p)
               (return cdr.p (json-backslash-char car.p))))))

(= json-string
  (on-result string
    (seq2 (match-is #\")
          (must "missing closing quote in JSON string"
                (seq1 (many (alt json-backslash-escape
                                 (match [isnt _ #\"])))
                      (match-is #\"))))))

(= json-array
  (seq2 (match-is #\[)
        (optional (cons-seq forward.json-value
                            (many (seq2 (skipwhite:match-is #\,)
                                        (must "a comma must be followed by a value"
                                              forward.json-value)))))
        (must "a JSON array must be terminated with a closing ]"
              (skipwhite:match-is #\]))))

(= json-object-kv
  (with-seq (key   skipwhite.json-string
             colon (must "a JSON object key string must be followed by a :"
                         (skipwhite:match-is #\:))
             value (must "a colon in a JSON object must be followed by a value"
                         forward.json-value))
    (list key value)))

(= json-object
   (on-result listtab
     (seq2 (match-is #\{)
           (comma-separated json-object-kv "comma must be followed by a key")
           (must "a JSON object must be terminated with a closing }"
                 (skipwhite:match-is #\})))))

(= json-value
  (skipwhite:alt json-true
                 json-false
                 json-null
                 json-number
                 json-string
                 json-array
                 json-object))

(def fromjson (s)
  (iflet (p r) (json-value (coerce s 'cons))
    (do (if p (err "Unexpected characters after JSON value" (coerce p 'string)))
        r)
    (err:string "not a JSON value: " s)))
