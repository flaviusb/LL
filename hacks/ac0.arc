(= ac-denil       (ac-scheme ac-denil))
(= ac-global-name (ac-scheme ac-global-name))
(= ac-niltree     (ac-scheme ac-niltree))

; for when we can't use assign

(mac ac-set-global (name val)
  (w/uniq (gname v)
    `(with (,gname (ac-global-name ,name)
            ,v ,val)
       (ac-scheme (namespace-set-variable-value! ,gname ,v))
       nil)))
