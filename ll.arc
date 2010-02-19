(each x '("ac1.arc" "urlencode0.arc" "between0.arc" "parsecomb0.arc" "tojson0.arc" "fromjson0.arc" "fileutils.arc") (load (+ "lib/" x)))

;redefine ensure-dir here for the moment
(def ensure-dir (path)
  (unless (dir-exists path)
    (makepath nil ((ac-scheme regexp-split) "/" path))))

(system "git clone git://github.com/flaviusb/vcstatic.git")

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
  `(tag (li class "login")
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

(mac navit (loc text)
  `(tag (li) (tag (a href ,(string loc)) (pr ,(string text)))))

(mac character-header ()
  `(do (navit "aq" "Action Queue") (navit "cs" "Character Sheet") (tag (li class "right-align") (w/rlink (do (logout-user get-user.req) "index.html") (pr (+ "Log out " get-user.req)))) nil))
;  `(tag (div)(tag (a href "aq")(pr "Action Queue"))(pr " ")(tag (a href "cs")(pr "Character Sheet"))(pr " ")(w/rlink (do (logout-user get-user.req) "index.html") (pr (+ "Log out " get-user.req)))))

(mac header ()
  `(tag (nav) (tag (ul) (navit "about" "About") (navit "rules" "House Rules") (if (and (~is req nil) (get-user req)) (character-header)
     (login-header)))))
(defop || req (page "Ascension Auckland" "style.css" ("jquery-1.3.2.min.js" "standard.js") (+ (tag header (tag h1 (pr "Nexus"))) (header) (br) (tag (img class "logo" src "NexusLogo.png")))))

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

(def shellesc (str)
  ((ac-scheme regexp-replace*) "([\"])" str "\\\\"))

(def textize (fi)
    (with (temp "" pipe nil acc "")
      (do (whilet li readc.fi (= temp (+ temp li)))
          (= pipe (pipe-from:string  "echo \"" shellesc.temp "\" | markdown -T "))
          (whilet lj readc.pipe (= acc (+ acc lj)))
          acc)))

(defop rules req
  (page "Ascension Auckland: House Rules" "style.css" ("jquery-1.3.2.min.js" "standard.js")
    (+
      (header)
      (tag (section class "generated-text") (w/cd "vcstatic" (cacheize "rules.text" "rules.html" textize))))))

(defop about req
  (page "About Ascension Auckland" "style.css" ("jquery-1.3.2.min.js" "standard.js")
    (+
      (header)
      (tag (section class "generated-text") (w/cd "vcstatic" (cacheize "about.text" "about.html" textize))))))

;(= actionsdone* (table))
; per user; [pending, held, done, future], personal, retainer - [by ref], ally - [by fnidish]

; set - called zf to avoid name collisions
(def zf ()
  (obj values (table) indices (table)))

(def zfill fill
    (let it (zf)
       (each x fill
         (insert it x))
       it))
(def zfilll (fill)
    (let it (zf)
      (each x fill
        (insert it x))
      it))
(def insert (zfs val)
  (do (if (is zfs nil) (= zfs (zf)))
      (= (zfs!values (+ (len zfs!indices) 1)) val)
      (= zfs!indices.val (+ (len zfs!indices) 1))
      zfs))
(def remove (zfs val)
  (do 
    (if (is zfs nil) (= zfs (zf))
      (if (~is zfs!indices.val nil)
        (do
            (with (pivot zfs!indices.val length (len zfs!indices))
                  (for x pivot length
                    (do (= zfs!values.x (zfs!values (+ x 1)))
                        (unless (is zfs!values.x nil) (= (zfs!indices zfs!values.x) x)))))
            (= zfs!indices.val nil))))
    zfs))

(def ∈ (el zfs)
  (~is zfs!indices.el nil))
(def set-member? (el zfs)
  (∈ el zfs))

(def ⊂ (zf1 zf2)
  (let ret t
    (each (y x) zf1!values
      (aif (is zf2!indices.x nil) (= ret (no it))))
     ret))
(def subset-of? (zf1 zf2)
  (⊂ zf1 zf2))

(def set->table (zfs)
  (if zfs zfs!values (table)))

;(def set->list (zfs)
;  ())
; multitable
(def multitable ()
  (obj tag->values (table) value->tags (table) tags (table) values (table)))
(def +tag (mt tag val)
  (do
      (if (is mt nil)
        (= mt (multitable)))
      (zap insert mt!tags.tag t)
      (zap insert mt!values.val t)
      (zap insert mt!tag->values.tag val)
      (zap insert mt!value->tags.val tag)
      mt))

(def -tag (mt tag val)
  (do (zap remove mt!tag->values.tag val)
      (zap remove mt!value->tags.val val)
      mt))

(def tags->values (mt . tags)
  (do
    (with (container (set->table (mt!tag->values car.tags)) acc (zf) tagset (zfilll tags))
      (do
        (each (y x) container
          (do (if (⊂ tagset (mt!value->tags x))
                (zap insert acc x))))
        acc))))

(= actionqueues* (table))
; each action queue is a multitable of type/data pairs, with type, date, and location tags
(def addaction (usr ty da loc)
  (do
      (+tag actionqueues*.usr ty  (list "type" ty "data" da))
      (+tag actionqueues*.usr loc (list "type" ty "data" da))
  ))

(defoptext addaction req
  (if (~is get-user.req nil)
    (do
      (addaction (get-user req) (arg req "ty") (arg req "da") (arg req "loc"))
      (prn "Success."))
     (prn "No success.")))

(defopjson showactions req
  (tojson (obj futureactions (aif (actionqueues* get-user.req) it 'nothing) pastactions (aif (actionsdone* get-user.req) it 'nothing))))

(defopjson submitactions req
  (do
    (parse-actions get-user.req (arg req "aq"))
    (tojson (obj message 'success futureactions (aif (actionqueue* get-user.req) it 'nothing) pastactions (aif (actionsdone* get-user.req) it 'nothing)))))

(= waitinglist* (table))
(mac w/touching (id . body)
  `(do1
     (do
       ,@body
     )
     (aif (waitinglist* id)
       (each x it
         (wake x)))))

; format [...,{ty: name, da: data}, ...]
(def parse-actions (usr json-data)
  ;assume this has been sanitized for the moment
  (w/touching usr
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

(= charsheets* (multitable))
; each charsheet should have an associated schema, and then be k,v pairs
; keys must be strings, values may be number, list or table
(def render-charsheet (charsheet) 
  (charsheet!schema charsheet))

(mac ret (name . body)
  `(let ,name nil
     ,@body
     ,name))

;(mac columns body
;  `(tag (div) ,@(ret foo (each x body (= foo (join foo (list (list 'tag '(div class "column") x))))))))

;(mac columns body
;  `(join (list 'tag '(div)) (mappend [list (list 'tag '(div) _)] ',body)))

(mac columns body
  ``(tag (div class "columns") ,@(mappend [mappend [list (list 'tag '(div class "column") _)] (eval _)] ',body) (prn)))


(mac w/lets (var expr . body)
  `(join '(let) '(,var) '(,expr)
     ',body))
(def columns2 (s) (eval (join '(columns) s)))

; page &body
; gold-body :title title-element :body &body
; columns &body
; dots number max

(= attributeblock* '((Intelligence Wits Resolve) (Strength Dexterity Stamina) (Presence Manipulation Composure)))
(= skillblock* '((Mental (Academics Computer Crafts Investigation Medicine Occult Politics Science)) (Physical (Athletics Brawl Drive Firearms Larceny Stealth Survival Weaponry)) (Social (Animal#\ Ken Empathy Expression Intimidation Persuasion Socialize Streetwise Subterfuge))))

(= charsheets* (table))
(= (charsheets* "foo") (obj attributes (table) skills (table)))
(each x (flat attributeblock*) (= (((charsheets* "foo") 'attributes) x) (coerce (* (rand) 5) 'int)))
(each x (flat skillblock*) (= (((charsheets* "foo") 'skills) x) (coerce (* (rand) 5) 'int)))

(mac locap-string body
  `(tag (span class "locap") (pr (string ',body))))

(mac norm-string body
  `(tag (span class "norm") (pr (string ',body))))

(def dots (name value out-of)
  (tag (span) (for x 1 value (tag (a href (string "javascript:click_dot('" name "', " value ");")) (tag (img src "black-dot.png")))) (for x (+ value 1) out-of (tag (a href (string "javascript:click_dot('" name "', " x ");")) (tag (img id (string name "/" x) src "white-dot.png"))))))

;(mac mac/k (name lst . body)) 
;(mac/k () )
(def spring () (tag (span class "stretch")))
(mac centered body `(tag (div class "centered") ,@body))
(mac right-align body `(tag (span class "right-align") ,@body))

(mac gold-box args
  (with (flag 'test title nil body nil)
    (each x args
      (case flag
        test    (case x
                  :title (= flag ':title)
                  @title (= flag '@title)
                  :body  (= flag ':body)
                  @body  (= flag '@body))
        :title  (do (= flag 'test) (push x title))
        @title  (do (= flag 'test) (zap join title x))
        :body   (do (= flag 'test) (push x body))
        @body   (do (= flag 'test) (zap join body x))))
    `(tag (div class "gold-box")
      (tag (span) ,@title)
      (tag (br))
      (tag (div) ,@body))))

(def mage-charsheet (charsheet)
  (with (bod1 (eval (join '(columns) (list:list 'quote (join  
                (list (join (list 'tag '(div)) (map1 [list 'tag '(div) (list 'locap-string _) '(tag (br))] '(Power Finesse Resistance))))
                (map1 [join (list 'tag '(div)) (map1 [list 'tag '(div) (list 'tag '(span) (list 'norm-string _) (list 'dots (string "attributes/" _) charsheet!attributes._ 5)) '(tag (br))] _) '(tag (br))] attributeblock*)))))
        bod2 (eval (join '(columns) (list:list 'quote 
                (mappend [join (list (list 'centered:locap-string (car _))) (map1 [list 'tag '(span) (list 'norm-string _) (list 'dots (string "skills/" _) charsheet!skills._ 5)] (car (cdr _)))] skillblock*)))))
  (tag (div)
    (gold-box :body (columns ))
    (gold-box :title (centered:locap-string Attributes)
      :body (eval bod1))
    (gold-box @title ((locap-string Skills)  (right-align:locap-string Other\ Traits))
      :body (eval bod2)))))
(defopjson csjson req
  (tojson (charsheets* get-user.req)))
(defop cs req
  (page "Ascension Auckland: Character sheet" "style.css" ("jquery-1.3.2.min.js" "standard.js") 
    (let cs (charsheets* get-user.req) 
      (+ (header) (tag (section class "charsheet") (tag (script type "application/javascript") (prn "\ninitialise_charsheet();")) (mage-charsheet cs))))))


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

(defop longpoll req
  ())

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
