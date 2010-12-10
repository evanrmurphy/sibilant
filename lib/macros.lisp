(mac cons (first rest)
  (macros.send (macros.list first) 'concat rest))

(mac join (glue arr)
  (concat "(" (translate arr) ").join(" (translate glue) ")"))

(mac list (&rest args)
  (concat "[ " (join ", " (map args translate)) " ]"))

(mac +   (&rest args) (concat "(" (join " + " (map args translate)) ")"))
(mac -   (&rest args) (concat "(" (join " - " (map args translate)) ")"))
(mac *   (&rest args) (concat "(" (join " * " (map args translate)) ")"))
(mac or  (&rest args) (concat "(" (join " || " (map args translate)) ")"))
(mac and (&rest args) (concat "(" (join " && " (map args translate)) ")"))
(mac >   (&rest args) (concat "(" (join " > " (map args translate)) ")"))
(mac <   (&rest args) (concat "(" (join " < " (map args translate)) ")"))
(mac <=  (&rest args) (concat "(" (join " <= " (map args translate)) ")"))
(mac >=  (&rest args) (concat "(" (join " >= " (map args translate)) ")"))
(mac !=  (&rest args) (concat "(" (join " !== " (map args translate)) ")"))

; node won't let me define this simple macro on one line
(mac /   (&rest args)
  (concat "(" (join " / " (map args translate)) ")"))

(mac mod (&rest args)
  (concat "(" (join " % " (map args translate)) ")"))

(mac pow (base exponent)
  (macros.call "Math.pow" base exponent))

(mac += (item increment)
  (concat (translate item) " += " (translate increment)))

(mac ++ (item)
  (concat "((" (translate item) ")++)"))

(mac dec (item)
  (concat "((" (translate item) ")--)"))

(mac get (arr i) (concat "(" (translate arr) ")[" (translate i) "]"))

(mac set (arr &rest kv-pairs)
  (join "\n" (bulk-map kv-pairs
		       (lambda (k v)
			 (concat "(" (translate arr) ")"
				 "[" (translate k) "] = " (translate v) ";")))))
				       
(mac send (object method &rest args)
  (concat (translate object) "." (translate method)
	  "(" (join ", " (map args translate)) ")"))

(mac new (fn)
  (concat "(new " (translate fn) ")"))

(mac regex (string &optional glim)
  ((get macros 'new) (macros.call "RegExp" string (or glim "undefined"))))

(mac timestamp ()
  (concat "\"" (send (new (-date)) to-string) "\""))

(mac comment (&rest contents)
  (map contents
       (lambda (item)
	 (join "\n" (map (send (translate item) split "\n")
			 (lambda (line) (concat "// " line)))))))

(mac meta (body)
  (eval (translate body)))

(mac apply (fn arglist)
  (macros.send fn 'apply 'undefined arglist))

(mac zero? (item)
  ((get macros "==") (translate item) 0))

(mac empty? (arr)
  (concat "((" (translate arr) ").length === 0)"))

(mac odd? (number)
  ((get macros "!=") 0
   (macros.mod (translate number) 2)))

(mac even? (number)
  ((get macros "==") 0
   (macros.mod (translate number) 2)))


(mac function? (thing)
  (concat "typeof(" (translate thing) ") === 'function'"))

(mac undefined? (thing)
  (concat "typeof(" (translate thing) ") === 'undefined'"))

(mac defined? (thing)
  (concat "typeof(" (translate thing) ") !== 'undefined'"))

(mac number? (thing)
  (concat "typeof(" (translate thing) ") === 'number'"))

(mac first (arr) (macros.get arr 0))
(mac second (arr) (macros.get arr 1))
(mac third (arr) (macros.get arr 2))
(mac fourth (arr) (macros.get arr 3))
(mac fifth (arr) (macros.get arr 4))
(mac sixth (arr) (macros.get arr 5))
(mac seventh (arr) (macros.get arr 6))
(mac eighth (arr) (macros.get arr 7))
(mac ninth (arr) (macros.get arr 8))

(mac rest (arr)
  (macros.send arr 'slice 1))

(mac length (arr)
  (macros.get arr "\"length\""))

(mac last (arr)
  (macros.get (macros.send arr 'slice -1) 0))

(mac if (arg truebody falsebody)
  (concat
   "(function() {"
   (indent (concat
	    "if (" (translate arg) ") {"
	    (indent (macros.do truebody))
	    "} else {"
	    (indent (macros.do falsebody))
	    "};"))
   "})()"))


(mac var (&rest pairs)
  (concat
    "var "
    (join
      ",\n    "
      (bulk-map
        pairs
        (lambda (name value)
          (concat (translate name) " = " (translate value)))))
	  ";"))

(mac == (first-thing &rest other-things)
  (var translated-first-thing (translate first-thing))
  (concat "("
          (join " &&\n "
                (map other-things
                     (lambda (thing)
                       (concat translated-first-thing
                               " === "
                               (translate thing)))))
          ")"))


(mac string? (thing)
  (concat "typeof(" (translate thing) ") === \"string\""))

(mac array? (thing)
  (var translated (concat "(" (translate thing) ")"))
  (concat translated " && "
	  translated ".constructor.name === \"Array\""))

(mac when (arg &rest body)
  (concat
   "(function() {"
   (indent (concat
	    "if (" (translate arg) ") {"
	    (indent (apply macros.do body))
	    "};"))
   "})()"))

(mac not (exp)
  (concat "(!" (translate exp) ")"))

(mac slice (arr start &optional end)
  (macros.send (translate arr) "slice" start end))

(mac inspect (&rest args)
  (join " + \"\\n\" + "
   (map args
	(lambda (arg)
	  (concat "\"" arg ":\" + " (translate arg))))))

(mac each (item array &rest body)
  (macros.send (translate array) 'for-each
	(apply macros.lambda (cons item body))))

(mac assign (&rest args)
  (join "\n"
	(bulk-map args (lambda (name value)
			 (concat (translate name) " = "
				 (translate value) ";")))))

(mac macro-list ()
  (concat "["
	  (indent (join ",\n"
			(map (-object.keys macros)
			     macros.quote)))
	  "]"))

(mac macex (name)
  (var macro (get macros (translate name)))
  (if macro
      (concat "// macro: " name "\n" (send macro to-string))
    "undefined"))

(mac throw (&rest string)
  (concat "throw new Error (" (join " " (map string translate)) ")"))

(mac as-boolean (expr)
  (concat "(!!(" (translate expr) "))"))

(mac force-semi () (concat ";\n"))

(mac chain (object &rest calls)
  (concat (translate object) " // chain"
	  (indent (join "\n"
		(map calls
		     (lambda (call, index)
		       (var method (first call))
		       (var args (rest call))
		       (concat "." (translate method)
			       "(" (join ", " (map args translate)) ")")))))))

(mac try (tryblock catchblock)
  (concat
   "(function() {"
   (indent (concat
	    "try {"
	    (indent (macros.do tryblock))
	    "} catch (e) {"
	    (indent (macros.do catchblock))
	    "}"))
   "})()"))

(mac while (condition &rest block)
  (macros.scoped
   (macros.var '**return-value**)
   (concat "while (" (translate condition) ") {"
           (indent (macros.assign '**return-value**
                                (apply macros.scoped block))))
   "}"
   '**return-value**))

(mac until (condition &rest block)
  (apply (get macros 'while)
         (cons ['not condition] block)))


(mac thunk (&rest args)
  (apply macros.lambda (cons [] args)))

(mac keys (obj)
  (macros.call "Object.keys" (translate obj)))

(mac delete (&rest objects)
  (join "\n" (map objects (lambda (obj)
                            (concat "delete " (translate obj) ";")))))

(mac delmac (macro-name)
  (delete (get macros (translate macro-name))) "")

(mac defhash (name &rest pairs)
  (macros.var name (apply macros.hash pairs)))

(mac arguments ()
  "(Array.prototype.slice.apply(arguments))")

(mac scoped (&rest body)
  (macros.call (apply macros.thunk body)))

(mac each-key (as obj &rest body)
  (concat "(function() {"
	  (indent
	   (concat "for (var " (translate as) " in " (translate obj) ") "
		   (apply macros.scoped body)
		   ";"))
	  "})();"))

(mac match? (regexp string)
  (macros.send string 'match regexp))

(mac switch (obj &rest cases)

  ;; the complexity of this macro indicates there's a problem
  ;; I'm not quite sure where to fix this, but it has to do with quoting.
  (var lines (list (concat "switch(" (translate obj) ") {")))
  (each (case-def) cases
	(var case-name (first case-def))
	(when (and (array? case-name)
		   (== (first case-name) 'quote))
	  (var second (second case-name))
	  (assign case-name (if (array? second)
			      (map second macros.quote)
			    (macros.quote second))))
	
	(var case-string
	  (if (array? case-name)
	      (join "\n" (map case-name (lambda (c)
					  (concat "case " (translate c) ":"))))
	    (if (== 'default case-name) "default:"
	      (concat "case " (translate case-name) ":"))))
	
	(lines.push (concat case-string
			    (indent (apply macros.do (case-def.slice 1))))))

  ; the following two lines are to get the whitespace right
  ; this is necessary because switches are indented weird
  (set lines (- lines.length 1)
       (chain (get lines (- lines.length 1)) (concat "}")))

  (concat "(function() {" (apply indent lines) "})()"))

