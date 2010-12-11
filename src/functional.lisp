(var functional exports)

(def bulk-map (arr f)
  (var index 0
    group-size f.length
    ret-arr [])

  (while (< index arr.length)
    (send ret-arr push
	  (apply f (send arr slice
			  index (+ index group-size))))
    (+= index group-size))
  ret-arr)

(def inject (start items f)
  (var value start)
  (when (array? items)
      (each (item index) items
	    (assign value (f value item index))))
  value)

(def map (items f)
  (inject [] items
	  (lambda (collector item index)
	    (send collector push (f item index))
	    collector)))

(def select (items f)
  (inject [] items
	  (lambda (collector item index)
	    (when (f item index)
	      (send collector push item))
	    collector)))

(def detect (items f)
  (var return-item undefined
    index 0
    items items)

  (until (or (== items.length index) return-item)
    (when (f (get items index) index)
      (assign return-item (get items index)))
    (++ index)))

(def reject (items f)
  (def args [ items f ])
  (select items (lambda () (not (apply f args)))))

(def compact (arr)
  (select arr (lambda (item) (as-boolean item))))

(each (export-function)
      '(inject map select detect reject compact bulk-map)
      (set exports export-function
	   (eval export-function)))
		  
     

		      
