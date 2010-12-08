(var functional exports)

(def bulk-map (arr fn)
  (var index 0
    group-size fn.length
    ret-arr (list))

  (while (< index arr.length)
    (send ret-arr push
	  (apply fn (send arr slice
			  index (+ index group-size))))
    (incr-by index group-size))
  ret-arr)

(def inject (start items fn)
  (var value start)
  (when (array? items)
      (each (item index) items
	    (setf value (fn value item index))))
  value)

(def map (items fn)
  (inject (list) items
	  (lambda (collector item index)
	    (send collector push (fn item index))
	    collector)))

(def select (items fn)
  (inject (list) items
	  (lambda (collector item index)
	    (when (fn item index)
	      (send collector push item))
	    collector)))

(def detect (items fn)
  (var return-item undefined
    index 0
    items items)

  (until (or (= items.length index) return-item)
    (when (fn (get items index) index)
      (setf return-item (get items index)))
    (incr index)))

(def reject (items fn)
  (var args (list items fn))
  (select items (lambda () (not (apply fn args)))))

(def compact (arr)
  (select arr (lambda (item) (as-boolean item))))

(each (export-function)
      '(inject map select detect reject compact bulk-map)
      (set exports export-function
	   (eval export-function)))
		  
     

		      
