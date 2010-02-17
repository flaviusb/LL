(def bytehex (i)
  (if (< i 16) (writec #\0))
  (pr (upcase:coerce i 'string 16)))

(def urlsafe (c)
  (or alphadig.c (in c #\- #\_ #\. #\~)))

(def charutf8 (c)
  (ac-scheme (ac-niltree (bytes->list (string->bytes/utf-8 (string c))))))

(def urlencode (s)
 (tostring
   (each c s
     (if (is c #\space)
          (pr #\+)
         urlsafe.c
          (pr c)
          (each i charutf8.c
            (writec #\%)
            (bytehex i))))))
