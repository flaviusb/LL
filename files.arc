;;; files.arc: dealing with Unix files.

;; File stats (modif time, file size, etc.), call the `stat' program.
; define 'cach/'defcach, versions of Arc's 'cache/'defcache working with
; any number of arguments (and giving more control over the cache)
;
; stat() one of the few syscall I think should be made accessible in ac.scm:
; nearly as mandatory as rename() if you want to play a bit with local files

(def cach (f time)
  (with (timef  (if (isa time 'fn) time (fn (e) time))
  	 cache  (table)
	 nilsym (uniq))
    (list 
      cache
      (fn args
        (= args (copy args))  ; Arc bug, 'invalidate won't work w/out copying
        (unless (aand cache.args (< (since it!time) (timef it)))
          (= cache.args (obj time (seconds)
	   	             val  (aif (apply f args) it nilsym))))
        (check cache.args!val [isnt _ nilsym])))))

; bug seems related to a confusion between Arc's nil-
; and Scheme's ()-terminated lists, when used as table keys

(= cached-fns* (table))

(mac defcach (name parms time . body)
  `(let (c f) (cach (fn ,parms ,@body) ,time)
     (= cached-fns*.f c)
     (safeset ,name f)))

(def invalidate (key cachedf)  
  (= cached-fns*.cachedf.key!time -1))

(def reset-cache (key cachedf)
  (invalidate key cachedf)
  (cachedf key))

(def out-from cmd+args  (tostring:system:string cmd+args))

(= filestat-cachetime*  5)  ; seconds

(defcach filestat (fname) (fn (e) filestat-cachetime*)
  ; todo: "--terse" only available in GNU stat, not POSIX
  ;       return a hash instead, coerce fields (?)
  (tokens:out-from "stat --terse " fname))

(def mtime (fname)  (int ((filestat fname) 12)))  ; 12th field

; remember key is always a list, even if single arg:
;  > (invalidate '("/etc/passwd") filestat)
; 'invalidate throws an error if key doesn't exist.


;; Temporary filenames, like `mktemp'
; 'tmpname is quite safe: 'file-exists is called atomically, 
; and the file is created to prevent another thread from using this name

(= tmp-dir*  "/tmp/")

(def tmpname ((o pfx (+ tmp-dir* "/arc.")) (o leng 10))
  (atlet nam (+ pfx (rand-string leng))
    (if (file-exists nam)
        (tmpname pfx leng)
        (do (w/outfile s nam)  ; to create the file
             nam))))

(mac w/tmpname (var . body)  ; because you'll forget to delete the tmpfile
  `(let ,var (tmpname)
     (after (do ,@body) 
            (rmfile ,var))))


;; Hash/Crypt (with salt).  
; maybe use sha256 for crypting, but still not optimal (i.e: not bcrypt)

 (def hashfile (fname (o algo 'sha1))
   (trim:out-from "openssl dgst -" algo "<" fname))

 (def hash (val (o algo 'sha1))
   (w/tmpname fnam
     (w/outfile s fnam (disp val s))
     (hashfile fnam algo)))

(def crypt (key (o salt/ref (rand-string 5)))
  (withs (parts (errsafe:tokens salt/ref #\$)
  	  salt  (if (len> parts 1) parts.0 salt/ref))
    (string salt #\$ (hash (string salt key)))))

(def goodcrypt (cand ref)  (is (crypt cand ref) ref))


;; General file utils

(def file-ext (fname)  ; get the file extension as downcased symbol
  (aand fname 
  	(check (tokens it #\.) ~single)
    	(sym:downcase:last it)))

(def dirname (fname)
  (let toks (tokens fname #\/)
    (if (no toks)
   	 "/"
	(single toks)
     	 "."
	 (string:intersperse #\/ (cut toks 0 -1)))))

(def prfile (fname (o to (stdout)))
  (w/infile s fname
    (whilet b (readb s)
      (writeb b to))))

(mac w/destfile (var fname . body)  ; safe high-level 'w/outfile
  (w/uniq gtmp
    `(let ,gtmp (tmpname)  ; todo: after (...) if exists delete (case of err)
       (w/outfile ,var ,gtmp ,@body)
       (mvfile ,gtmp ,fname))))

(def cpfile (src dest)
  (w/destfile o dest (prfile src o))
  dest)

;(def writefile (val file)  
;  ; because "x.tmp: no such file or directory"
;  ; but (a) need to patch ac.scm to get mvfile be more like `mv'
;  ; and less like rename() syscall (i.e: rename doesn't work on != fs,
;  ; and at least on my PC, /tmp and /home are different fs),
;  ; (b) your code has a problem anyway if you get "x.tmp: no such" :-)
;  (w/destfile o file (write val o))
;  val)


;; MIME types

(= mimetypes*  (obj html    "text/html"
   		    htm     "text/html"
		    css     "text/css"
		    js	    "application/x-javascript"
		    gif     "image/gif"
		    jpeg    "image/jpeg"
		    jpg	    "image/jpeg"
		    png	    "image/png"
		    tif	    "image/tiff"
		    tiff    "image/tiff"
		    ico	    "image/x-icon"
		    bmp	    "image/x-ms-bmp"
		    rss	    "text/xml"
		    atom    "application/atom+xml"
		    txt	    "text/plain"
		    text    "text/plain"
		    pdf	    "application/pdf"
		    shtml   "text/html"
		    xml     "text/xml"
		    mml	    "text/mathml"
		    jad	    "text/vnd.sun.j2me.app-descriptor"
		    wml	    "text/vnd.wap.wml"
		    htc	    "text/x-component"
		    wbmp    "image/vnd.wap.wbmp"
		    jng	    "image/x-jng"
		    jar	    "application/java-archive"
		    war	    "application/java-archive"
		    ear	    "application/java-archive"
		    hqx	    "application/mac-binhex40"
		    doc	    "application/msword"
		    ps	    "application/postscript"
		    eps	    "application/postscript"
		    ai	    "application/postscript"
		    rtf	    "application/rtf"
		    xls	    "application/vnd.ms-excel"
		    ppt	    "application/vnd.ms-powerpoint"
		    wmlc    "application/vnd.wap.wmlc"
		    xhtml   "application/vnd.wap.xhtml+xml"
		    cco	    "application/x-cocoa"
		    jardiff "application/x-java-archive-diff"
		    jnlp    "application/x-java-jnlp-file"
		    run	    "application/x-makeself"
		    pl	    "application/x-perl"
		    pm	    "application/x-perl"
		    prc	    "application/x-pilot"
		    pdb	    "application/x-pilot"
		    rar	    "application/x-rar-compressed"
		    rpm	    "application/x-redhat-package-manager"
		    sea	    "application/x-sea"
		    swf	    "application/x-shockwave-flash"
		    sit	    "application/x-stuffit"
		    tcl	    "application/x-tcl"
		    tk	    "application/x-tcl"
		    der	    "application/x-x509-ca-cert"
		    pem	    "application/x-x509-ca-cert"
		    crt	    "application/x-x509-ca-cert"
		    xpi	    "application/x-xpinstall"
		    zip	    "application/zip"
		    mid	    "audio/midi"
		    midi    "audio/midi"
		    kar	    "audio/midi"
		    mp3	    "audio/mpeg"
		    ra	    "audio/x-realaudio"
		    3gpp    "video/3gpp"
		    3gp	    "video/3gpp"
		    mpeg    "video/mpeg"
		    mpg	    "video/mpeg"
		    mov	    "video/quicktime"
		    flv	    "video/x-flv"
		    mng	    "video/x-mng"
		    asx	    "video/x-ms-asf"
		    asf	    "video/x-ms-asf"
		    wmv	    "video/x-ms-wmv"
		    avi	    "video/x-msvideo"))

(def mimetype (fname (o failv "application/octet-stream"))
  (or (mimetypes* (file-ext fname)) failv))


;; 'db: on-disk persistent 'table, w/ delayed, buffered writes

(= buffered-execs* (table))

(def buffer-exec (f (o delay 0.5))
  (unless buffered-execs*.f
    (= buffered-execs*.f 
       (thread (sleep delay) (wipe buffered-execs*.f) (f)))))

(= dbs* ())

(def db (fname (o delay 1))
  (withs (tbl    (safe-load-table fname)
	  savf   (fn () (save-table tbl fname))
	  smartf (fn ((o force)) 
	  	   (if force (savf) (buffer-exec savf delay))))
    (push (list tbl smartf) dbs*)
    tbl))

(let _sref sref
  (def sref (com val ind)
    (do1 (_sref com val ind)
         (awhen (and (isa com 'table) (alref dbs* com)) (it))))
)

; maybe remove 'db, it kinda sucks.
; persistence is a good solution to a bad overall design.
; too much magic.  and redefining 'sref smells like poop