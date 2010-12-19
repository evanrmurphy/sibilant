(mac cons (first rest)
  (macros.send (macros.list first) 'concat rest)) ; s/concat/\+/ doesn't compile

(mac join (glue arr)
  (+ "(" (translate arr) ").join(" (translate glue) ")"))

(mac list (&rest args)
  (+ "[ " (join ", " (map args translate)) " ]"))

(mac +   (&rest args) (+ "(" (join " + " (map args translate)) ")"))
(mac -   (&rest args) (+ "(" (join " - " (map args translate)) ")"))
(mac *   (&rest args) (+ "(" (join " * " (map args translate)) ")"))
(mac or  (&rest args) (+ "(" (join " || " (map args translate)) ")"))
(mac and (&rest args) (+ "(" (join " && " (map args translate)) ")"))
(mac >   (&rest args) (+ "(" (join " > " (map args translate)) ")"))
(mac <   (&rest args) (+ "(" (join " < " (map args translate)) ")"))
(mac <=  (&rest args) (+ "(" (join " <= " (map args translate)) ")"))
(mac >=  (&rest args) (+ "(" (join " >= " (map args translate)) ")"))
(mac !=  (&rest args) (+ "(" (join " !== " (map args translate)) ")"))

; node won't let me define this simple macro on one line
(mac / (&rest args)
  (+ "(" (join " / " (map args translate)) ")"))

(mac mod (&rest args)
  (+ "(" (join " % " (map args translate)) ")"))

(mac pow (base exponent)
  (macros.call "Math.pow" base exponent))

(mac += (item increment)
  (+ (translate item) " += " (translate increment)))

(mac ++ (item)
  (+ "((" (translate item) ")++)"))

                                        ; sibilant won't compile if you try and call this --
(mac dec (item)
  (+ "((" (translate item) ")--)"))

(mac get (arr i)
  (+ "(" (translate arr) ")[" (translate i) "]"))

(mac set (arr &rest kv-pairs)
  (join "\n" (bulk-map kv-pairs
                       (fn (k v)
                         (+ "(" (translate arr) ")"
                            "[" (translate k) "] = " (translate v) ";")))))

(mac send (object method &rest args)
  (+ (translate object) "." (translate method)
     "(" (join ", " (map args translate)) ")"))

(mac new (fn)
  (+ "(new " (translate fn) ")"))

(mac regex (string glim)
  ((get macros 'new) (macros.call "RegExp" string (or glim "undefined"))))

(mac timestamp ()
  (+ "\"" (send (new (-date)) to-string) "\""))

(mac comment (&rest contents)
  (map contents
       (fn (item)
         (join "\n" (map (send (translate item) split "\n")
                         (fn (line) (+ "// " line)))))))

(mac meta (body)
  (eval (translate body)))

(mac apply (fn arglist)
  (macros.send fn 'apply 'undefined arglist))

(mac zero? (item)
  ((get macros "==") (translate item) 0))

(mac empty? (arr)
  (+ "((" (translate arr) ").length === 0)"))

(mac odd? (number)
  ((get macros "!=") 0
   (macros.mod (translate number) 2)))

(mac even? (number)
  ((get macros "==") 0
   (macros.mod (translate number) 2)))

(mac function? (thing)
  (+ "typeof(" (translate thing) ") === 'function'"))

(mac undefined? (thing)
  (+ "typeof(" (translate thing) ") === 'undefined'"))

(mac defined? (thing)
  (+ "typeof(" (translate thing) ") !== 'undefined'"))

(mac number? (thing)
  (+ "typeof(" (translate thing) ") === 'number'"))

(mac first   (arr) (macros.get arr 0))
(mac second  (arr) (macros.get arr 1))
(mac third   (arr) (macros.get arr 2))
(mac fourth  (arr) (macros.get arr 3))
(mac fifth   (arr) (macros.get arr 4))
(mac sixth   (arr) (macros.get arr 5))
(mac seventh (arr) (macros.get arr 6))
(mac eighth  (arr) (macros.get arr 7))
(mac ninth   (arr) (macros.get arr 8))

(mac rest (arr)
  (macros.send arr 'slice 1))

(mac length (arr)
  (macros.get arr "\"length\""))

(mac last (arr)
  (macros.get (macros.send arr 'slice -1) 0))

(mac if (arg truebody falsebody)
  (+ "(function() {"
     (indent (+ "if (" (translate arg) ") {"
                (indent (macros.do truebody))
                "} else {"
                (indent (macros.do falsebody))
                "};"))
     "}).call(this)"))

; want to name `?:` but can't yet

(mac ?: (c t e)
  (+ "(" (translate c) " ? " t
                       " : " e")"))

(mac var= (&rest pairs)
     (+ "var "
        (join ",\n    "
              (bulk-map
               pairs
               (fn (name value)
                 (+ (translate name) " = " (translate value)))))
        ";"))

(mac == (first-thing &rest other-things)
  (var= translated-first-thing (translate first-thing))
  (+ "("
     (join " &&\n "
           (map other-things
                (fn (thing)
                  (+ translated-first-thing
                     " === "
                     (translate thing)))))
     ")"))

(mac string? (thing)
  (+ "typeof(" (translate thing) ") === \"string\""))

(mac array? (thing)
  (var= translated (+ "(" (translate thing) ")"))
  (+ translated " && "
     translated ".constructor.name === \"Array\""))

(mac when (arg &rest body)
  (+ "(function() {"
     (indent (+
              "if (" (translate arg) ") {"
              (indent (apply macros.do body))
              "};"))
     "})()"))

(mac not (exp)
  (+ "(!" (translate exp) ")"))

(mac slice (arr start end)
  (macros.send (translate arr) "slice" start end))

(mac inspect (&rest args)
  (join " + \"\\n\" + "
        (map args
             (fn (arg)
                 (+ "\"" arg ":\" + " (translate arg))))))

(mac each (item array &rest body)
  (macros.send (translate array) 'for-each
               (apply macros.fn (cons item body))))

(mac = (&rest args)
  (join "\n"
        (bulk-map args (fn (name value)
                         (+ (translate name) " = "
                            (translate value) ";")))))

(mac macro-list ()
  (+ "["
     (indent (join ",\n"
                   (map (-object.keys macros)
                        macros.quote)))
     "]"))

(mac macex (name)
  (var= macro (get macros (translate name)))
  (if macro
      (+ "// macro: " name "\n" (send macro to-string))
      "undefined"))

(mac throw (&rest string)
  (+ "throw new Error (" (join " " (map string translate)) ")"))

(mac as-boolean (expr)
  (+ "(!!(" (translate expr) "))"))

(mac force-semi () (+ ";\n"))

(mac chain (object &rest calls)
  (+ (translate object) " // chain"
     (indent (join "\n"
                   (map calls
                        (fn (call, index)
                            (var= method (first call))
                            (var= args (rest call))
                            (+ "." (translate method)
                               "(" (join ", " (map args translate)) ")")))))))

(mac try (tryblock catchblock)
  (+ "(function() {"
     (indent (+ "try {"
                (indent (macros.do tryblock))
                "} catch (e) {"
                (indent (macros.do catchblock))
                "}"))
     "})()"))

(mac while (condition &rest block)
  (macros.scoped
   ((get macros 'var=) '**return-value**)
   (+ "while (" (translate condition) ") {"
      (indent ((get macros '=) '**return-value**
               (apply macros.scoped block))))
   "}"
   '**return-value**))

(mac until (condition &rest block)
  (apply (get macros 'while)
         (cons ['not condition] block)))


(mac thunk (&rest args)
  (apply macros.fn (cons [] args)))

(mac keys (obj)
  (macros.call "Object.keys" (translate obj)))

(mac delete (&rest objects)
  (join "\n"
        (map objects (fn (obj)
                       (+ "delete " (translate obj) ";")))))

(mac delmac (macro-name)
  (delete (get macros (translate macro-name))) "")

(mac defhash (name &rest pairs)
  ((get macros 'var=) name (apply macros.hash pairs)))

(mac arguments ()
  "(Array.prototype.slice.apply(arguments))")

(mac scoped (&rest body)
  (macros.call (apply macros.thunk body)))

(mac each-key (as obj &rest body)
  (+ "(function() {"
     (indent
      (+ "for (var " (translate as) " in " (translate obj) ") "
         (apply macros.scoped body)
         ";"))
     "})();"))

(mac match? (regexp string)
  (macros.send string 'match regexp))

(mac switch (obj &rest cases)

     ;; the complexity of this macro indicates there's a problem
     ;; I'm not quite sure where to fix this, but it has to do with quoting.
     (var= lines (list (+ "switch(" (translate obj) ") {")))
     (each (case-def) cases
           (var= case-name (first case-def))
           (when (and (array? case-name)
                      (== (first case-name) 'quote))
             (var= second (second case-name))
             (= case-name (if (array? second)
                              (map second macros.quote)
                              (macros.quote second))))
           
           (var= case-string
                 (if (array? case-name)
                     (join "\n" (map case-name (fn (c)
                                                   (+ "case " (translate c) ":"))))
                     (if (== 'default case-name) "default:"
                         (+ "case " (translate case-name) ":"))))
           
           (lines.push (+ case-string
                          (indent (apply macros.do (case-def.slice 1))))))

                                        ; the following two lines are to get the whitespace right
                                        ; this is necessary because switches are indented weird
     (set lines (- lines.length 1)
          (chain (get lines (- lines.length 1))
                 (concat "}"))) ; s/concat/\+/ doesn't compile

     (+ "(function() {" (apply indent lines) "})()"))

