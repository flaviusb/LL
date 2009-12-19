(def return (new-parse-position return-value)
  (list new-parse-position return-value))

(def match (f)
  (only (fn (p)
          (let x car.p
            (if (f x)
                 (return cdr.p x))))))

(def alt parsers
  (fn (p)
    (some [_ p] parsers)))

(def seq parsers
  (fn (p)
    ((afn (p parsers a)
       (if parsers
            (iflet (p2 r) (car.parsers p)
              (self p2 cdr.parsers (cons r a)))
            (return p rev.a)))
     p parsers nil)))

(def many (parser)
  (fn (p)
    ((afn (p a)
       (iflet (s2 r) (parser p)
         (self s2 (cons r a))
         (return p rev.a)))
     p nil)))

(def on-result (f parser)
  (fn (p)
    (iflet (p2 r) (parser p)
      (return p2 (f r)))))

(mac with-result (vars parser . body)
  `(on-result (fn (,vars) ,@body)
              ,parser))

(mac with-seq (vars-parsers . body)
  (withs (ps (pair vars-parsers)
          vars (map car ps)
          parsers (map cadr ps))
    `(on-result (fn (,vars) ,@body) (seq ,@parsers))))

(def cons-seq (a b)
  (with-seq (r  a
             rs b)
    (cons r rs)))

(def many1 (parser)
  (cons-seq parser
            (many parser)))

(def must (errmsg parser)
  (fn (p)
    (or (parser p)
        (err errmsg))))

(def seqi (i parsers)
  (with-result results (apply seq parsers)
    (results i)))

(def seq1 p (seqi 0 p))

(def seq2 p (seqi 1 p))

(def optional (parser)
  (alt parser
       (fn (p)
         (return p nil))))

(mac forward (parser)
  (w/uniq p
    `(fn (,p) (,parser ,p))))

(def match-is (x)
  (match [is x _]))

(def match-literal (pat val)
  (with (patlist (coerce pat 'cons)
         patlen  len.pat)
    (fn (p)
      (if (begins p patlist)
           (return (nthcdr patlen p) val)))))

(def parse-intersperse (separator parser must-message)
  (optional (cons-seq parser
                      (many (seq2 separator
                                  (must must-message parser))))))

(def skipw (p)
  (mem nonwhite p))

(def skipwhite (parser)
  (fn (p)
    (parser (skipw p))))

(def comma-separated (parser must-message)
  (parse-intersperse (skipwhite:match-is #\,) parser must-message))
