(each x '("ac1.arc" "urlencode0.arc" "between0.arc" "parsecomb0.arc" "tojson0.arc" "fromjson0.arc" "fileutils.arc") (load (+ "lib/" x)))

;redefine ensure-dir here for the moment
(def ensure-dir (path)
  (unless (dir-exists path)
    (makepath nil ((ac-scheme regexp-split) "/" path))))

(mac page (title cssname jsname . body)
  `(do (gendoctype)
       (tag (html xmlns "http://www.w3.org/1999/xhtml") 
         (tag (head) 
           (tag (title) (pr ,title))
           (tag (link rel "stylesheet" type "text/css" href ,cssname) (pr ""))
           (each x '(,@jsname) (tag (script type "application/javascript" src x))))
         (tag (body)
           ,@body))))


(= characters* (table))
(= cabals* (table))

;initial-div
;request
;response

(mac login-header ()
  `(tag (div class "login")
   (if (tag (a href "#" onclick "ShowLogin()") (pr "Log in"))
   (tag (fieldset id "signing_menu" class "common-form")
     (tag (form method "post" id "signin" action "/sessions")
       (tag (p) (tag (label for "u")(pr "Username"))
       (tag (input type "text" id "u" name "u" value "" title "u")))       
       (tag (p) (tag (label for "p")(pr "Password"))
       (tag (input type "password" id "p" name "p" value "" title "p")))
       (tag (p class "remember") (tag (input type "submit" id "signin-submit" value "Sign in"))
       (tag (input type "checkbox" id "remember" name "remember_me" value "1"))
       (tag (label for "remember") (pr "Remember me")))
     )
   ))))

(mac character-header ()
  `(tag (div)(tag (a href "aq")(pr "Action Queue"))(pr " ")(tag (a href "cs")(pr "Character Sheet"))(pr " ")(w/rlink (do (logout-user get-user.req) "index.html") (pr (+ "Log out " get-user.req)))))

(mac header ()
  `(tag (p class "blue") (pr " ") (tag (span) (tag (a href "about")(pr "About")) (pr " ") (tag (a href "rules")(pr "House Rules")) (tag (div class "header")(if (and (~is req nil) (get-user req)) (character-header)
                                (login-header))))))
(defop || req (page "Ascension Auckland" "style.css" ("jquery-1.3.2.min.js" "standard.js") (tag (div) (header) (tag h1 (pr "Nexus")) (tag (div)(tag (img class "logo" src "NexusLogo.png"))))))

(defopr index.html req #\/)

(def eschr (chr)
  (case chr   #\<        "&#60;" 
              #\>        "&#62;"
              #\"        "&#34;"
              #\'        "&#39;"
              #\&        "&#38;"
              #\newline  "<br />\n"
                         chr))

; Because of stdlib limitations, we cannot get file modification time in a platform portable way
; Instead, we explicitly flush the cache, and otherwise just use the existing file
; As the 'cache' is rev + processing -> temp file with rev identifier, the main reason to flush
; the 'cache' is when the processing method changes
(def cacheize (file name proc (o revi nil))
  (do
    (if (is revi nil) (= revi (cut (readline:pipe-from:string "git log " file) 7)))
    (let fl (+ "static-cache/" revi ":" name)
      (if (file-exists fl)
          (w/infile i fl
            (whilet b (readc i)
              (writec b)))
          (w/outfile fo fl
              (let fi (pipe-from:string "git show " revi ":" file)
                (let str proc.fi
                  (do (disp str fo)
                      (disp str)))))))))

(def clear-cache-directories ()
  (each x cachedirs* (do (rm-rf x) (mkdir x))))

(def textize (fi)
    (let temp ""
      (do (whilet li (eschr readc.fi) (= temp (+ temp li)))
          (= temp ((ac-scheme regexp-replace*) "^h([1234]). ([^\n]*)<br />\n" temp "<h\\1>\\2</h\\1>\n"))
          (= temp ((ac-scheme regexp-replace*) "\nh([1234]). ([^\n]*)<br />\n" temp "\n<h\\1>\\2</h\\1>\n"))
          temp)))

(defop rules req
  (page "Ascension Auckland: House Rules" "style.css" ("jquery-1.3.2.min.js" "standard.js")
    (tag (div)
      (header)
      (cacheize "static/rules.text" "rules.html" textize))))

(defop about req
  (page "About Ascension Auckland" "style.css" ("jquery-1.3.2.min.js" "standard.js")
    (tag (div)
      (header)
      (cacheize "static/about.text" "about.html" textize))))

;(= actionsdone* (table))
; per user; [pending, held, done, future], personal, retainer - [by ref], ally - [by fnidish]

; set - called zf to avoid name collisions
(def zf ()
  (obj values (table) indices (table)))

(def zfill fill
    (let it (zf)
      (do
        (each x fill
          (insert it x))
        it)))
(def insert (zfs val)
  (do (if (is zfs nil) (= zfs (zf)))
      (= (zfs!values (+ (len zfs!indices) 1)) val)
      (= zfs!indices.val (+ (len zfs!indices) 1))
      zfs))
(def remove (zfs val)
  (if (is zfs nil) (= zfs (zf))
    (if (~is zfs!indices.val nil)
      (do
          (with (pivot zfs!indices.val length (len zfs!indices))
                (for x pivot length
                  (do (= zfs!values.x (zfs!values (+ x 1)))
                      (unless (is zfs!values.x nil) (= (zfs!indices zfs!values.x) x)))))
          (= zfs!indices.val nil)))))

(def ∈ (el zfs)
  (~is zfs!indices.el nil))
(def set-member? (el zfs)
  (∈ el zfs))

(def ⊂ (zf1 zf2)
  (let ret t
    (do 
      (each (y x) (zf1!values)
        (aif (is zf2!indices.x nil) (= ret it)))
       ret)))
(def subset-of? (zf1 zf2)
  (⊂ zf1 zf2))

(def set->table (zfs)
  zfs!values)

;(def set->list (zfs)
;  ())
; multitable
(def multitable ()
  (obj tag->values (zf) value->tags (zf) tags (zf) values (zf)))
(def +tag (mt tag val)
  (do (zap insert mt!tags.tag t)
      (zap insert mt!values.val t)
      (zap insert mt!tag->values.tag val)
      (zap insert mt!value->tags.val tag)))

(def -tag (mt tag val)
  (do (remove mt!tags->values.tag val)
      (remove mt!values->tags.val val)))

(def tags->values (mt . tags)
  (do
    (with (container (set->table (mt!tag->values car.tags)) acc (zf) tagset (zfill tags))
      (do
      (map prn (list container acc tagset))
      (each (y x) container
        (if (⊂ mt!value->tags.x tagset)
            (zap insert acc x)))
      acc))))

(= actionqueues* (table))
(def addaction (usr ty da loc)
  (do
    (= actionqueues*.usr.loc (join actionqueues*.usr.loc (list (obj "date" "future" "type" ty "data" da))))
  ))

(defoptext addaction req
  (if (~is get-user.req nil)
    (do
      (addaction (get-user req) (arg req "ty") (arg req "da") (arg req "loc"))
      (prn "Success."))
     (prn "No success.")))

(defopjson showactions req
  (tojson (obj futureactions (aif (actionqueues* get-user.req) it 'nothing) pastactions (aif (actionsdones* get-user.req) it 'nothing))))

(defopjson submitactions req
  (do
    (parse-actions get-user.req (arg req "aq"))
    (tojson (obj message 'success futureactions (aif (actionqueue* get-user.req) it 'nothing) pastactions (aif (actionsdone* get-user.req) it 'nothing)))))

; format [...,{ty: name, da: data}, ...]
(def parse-actions (usr json-data)
  ;assume this has been sanitized for the moment
  (do
    (= (actionqueue* usr) '())
    (let parsed-data (fromjson json-data)
      (let end (- (len parsed-data) 1)
      (if (>= end 0)
        (for x 0 end
          (addaction usr (parsed-data.x "ty") (parsed-data.x "da"))))))
  ))

(def make-reader ()
  ())

(def make-writer ()
  ())

(mac defc ()
  ())

(clear-cache-directories)
(load-userinfo)

(defopr sessions req
  (login-handler req 'login (list (fn (a b) "index.html") "index.html")))

(mac actions ()
  `(tag (div class "containerthing")
     (tag (div class "messagepane"))
     (tag (div class "actions")
       (tag (div class "deadactions"))
       (tag (div class "liveactions"))
   )))

(defop aq req
  (page "Ascension Auckland: Action Queue" "style.css" ("jquery-1.3.2.min.js" "jquery-ui-1.7.2.custom.min.js" "standard.js")
    (tag (div)
         (tag (script type "application/javascript") (pr "
<![CDATA[
$(document).ready(function(){
  actionise();
  get_action_queue_from_server();
});
]]>
"))
         (header)
         (actions))))

; redefine login page for the moment; deal with this in a more ajaxy way in future
;(def login-page (switch (o msg nil) (o afterward hello-page))
;  (page "Log in" "style.css" ("jquery-1.3.2.min.js" "standard.js") (tag (div) 
;    (let req nil (header)) 
;    (pagemessage msg)
;    (when (in switch 'login 'both)
;      (login-form "Login" switch login-handler afterward)
;      (hook 'login-form afterward)
;      (br2))
;    (when (in switch 'register 'both)
;      (login-form "Create Account" switch create-handler afterward)))))



(thread:serve 8080)
