(each x '("urlencode0.arc" "between0.arc" "parsecomb0.arc" "tojson0.arc" "fromjson0.arc") (load (+ "lib/" x)))


(def listtag (a) (eval `(attribute ,@a opstring)))
(def newtag (q . r) (each x r (eval `(listtag '(,q ,x)))))
(newtag 'link 'rel 'type 'href) 
(newtag 'p 'class)
(newtag 'script 'type 'src)
(newtag 'div 'class 'id)
(newtag 'span 'class 'id)
(newtag 'canvas 'id)
(newtag 'a 'href 'onclick)
(newtag 'img 'src 'class)
(newtag 'fieldset 'id 'class)
(newtag 'form 'method 'id 'action)
(newtag 'input 'id 'name 'type 'value 'title 'tabindex)
(newtag 'label 'for)

(mac page (title cssname jsname . body)
  `; Put Doctype in here
  (tag (html) 
     (tag (head) 
       (tag (title) (pr ,title))
       (tag (link rel "stylesheet" type "text/css" href ,cssname) (pr ""))
       (each x '(,@jsname) (tag (script type "text/javascript" src x)))
     (tag (body)
       ,@body))))

(= *players* (table))
(= *characters* (table))
(= *cabals* (table))

(= (*players* 'test) (obj 'name 'test 'password 'password))

;actions as a list
(= *actions* ())
(def action-pane ()
  (tag (div class "actionpane")(tag (script type "javascript")(pr ""))))
;initial-div
;request
;response

(mac login-header ()
  `(tag (div class "login")
   (if (tag (a href "#" onclick "ShowLogin()") (pr "Log in"))
   (tag (fieldset id "signing_menu" class "common-form")
     (tag (form method "post" id "signin" action "http://localhost:8080/sessions")
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
  `(tag (div)(pr "FOOOOOOO")))

(mac header ()
  `(tag (p class "blu") (pr " ") (tag (div class "header")(if (get-user req) (character-header)
                                (login-header)))))
(defop index.html req (page "Ascension Auckland" "style.css" ("jquery-1.3.2.js" "standard.js") (tag (div) (header) (tag h1 (pr "Nexus")) (tag (div)(tag (img class "logo" src "NexusLogo.png"))))))

(defop || req "index.html")

(= actionsdone* (table))
; format order date type data
; order can be used as a uuid; it is monotonically increasing
(= actionqueue* (table))
(= uuid2order* (table))
(= order2uuid* (table))
; format uuid date type data
(= uuidtop* 0)
(= ordertop* 0)
(def addaction (ty da)
  (do
    (= (order2uuid* (++ ordertop*)) (++ uuidtop*))
    (= (uuid2order* uuidtop*) ordertop*)
    (= (actionqueue* uuidtop*) (obj "order" ordertop* "date" "future" "type" ty "data" da))
  ))

(defop addaction req
  (do
    (addaction (arg req "type") (arg req "data"))
    pr req))

(defop showactions req
  (pr (tojson actionqueue*)))

; format [...,{ty: name, da: data}, ...]
(def parse-actions (json-data)
  ;assume this has been sanitized
  (do
    (= uuidtop* 0)
    (= ordertop* 0)
    (= actionqueue* (table))
    (= uuid2order* (table))
    (= order2uuid* (table))
    (let parsed-data (fromjson json-data)
      ((each x (json-data)
        (addaction x!ty x!da))))
  ))
(defop aq req
  ())

(def make-reader ()
  ())

(def make-writer ()
  ())

(mac defc ()
  ())

(load-userinfo)
(create-acct "foo" "foot")

(def logged-in (user ip)
  ;(page "Ascension Auckland" "style.css" ("jquery-1.3.2.js" "standard.js") ()))
  ;(pr "Foo")
  "index.html")

(defop sessions req
  (login-handler req 'login hello-page))

(thread:serve 8080)
