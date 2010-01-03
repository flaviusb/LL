; Some file utils

(= lastdir* ((ac-scheme current-directory)))

(def cd (path)
  (do (= lastdir* ((ac-scheme current-directory)))
      (if (and (~is path nil) (~is path "")) ((ac-scheme current-directory) path)) ))

(def cd- ()
  (let templastdir ((ac-scheme current-directory))
    (do ((ac-scheme current-directory) lastdir*)
        (= lastdir* templastdir))))

;ch 19
(mac w/cd (path . block)
  (w/uniq retdir
      `(do
         (let ,retdir ((ac-scheme current-directory))
         (do (cd ,path)
             ,@block
             (cd ,retdir))))))

(def makepath (base path)
  (w/cd base
    (if (~is car.path nil)
        (do 
          (if (~dir-exists car.path)
            ((ac-scheme make-directory) car.path))
          (makepath car.path cdr.path)))))

(def mkdir (first . rest)
  (makepath nil first rest))

;(def rm (path)
;  ((ac-scheme file-exists?)))

