(set sibilant 'tokens {})

(set sibilant.tokens
     'regex              "(\\/(\\\\\\\/|[^\\/\\n])+\\/[glim]*)"
     'comment            "(;.*)"
     'string             "(\"(([^\"]|(\\\\\"))*[^\\\\])?\")"
     'number             "(-?[0-9.]+)"
     'literal            "([*.$a-zA-Z-=+][*.a-zA-Z0-9-=+]*(\\?|!)?)"
     'special            "([&']?)"
     'other-char         "([><=!\\+\\/\\*-]+)"
     'open-paren         "(\\()"
     'special-open-paren "('?\\()"
     'close-paren        "(\\))"
     'alternative-parens "\\{|\\[|\\}|\\]"
     'special-literal    (+ sibilant.tokens.special
                            sibilant.tokens.literal))

(set sibilant 'token-precedence
     '(regex comment string number special-literal other-char
       special-open-paren close-paren alternative-parens))

(var= tokenize
  (= sibilant.tokenize
     (fn (string)
       (var= tokens []
             parse-stack [tokens]
             specials [])

       (def accept-token (token)
         (send (get parse-stack 0) push token))

       (def increase-nesting ()
         (var= new-arr [])
         (accept-token new-arr)
         (parse-stack.unshift new-arr))

       (def decrease-nesting ()
         (specials.shift)
         (parse-stack.shift)
         (if (zero? parse-stack.length)
             (throw (+ "unbalanced parens:\n"
                       (call inspect parse-stack)))))

       (def handle-token (token)
         (var= special (first token)
               token token)
         (if (== special "'") (do (= token (token.slice 1))
                                  (increase-nesting)
                                  (accept-token 'quote))
                              (= special false))

           (specials.unshift (as-boolean special))

           (switch token
             ("(" (increase-nesting))
             (("]" "}" ")") (decrease-nesting))
             ("{" (increase-nesting) (accept-token 'hash))
             ("[" (increase-nesting) (accept-token 'list))
             (default
               (if (token.match (regex (+ "^" sibilant.tokens.number "$")))
                    (accept-token (parse-float token))
                   (accept-token token))))

           (if (and (!= token "(")
                    (specials.shift))
               (decrease-nesting)))

         (var= ordered-regexen
                (map sibilant.token-precedence
                     (fn (x) (get sibilant.tokens x)))
               master-regex
                (regex (join "|" ordered-regexen) 'g))

         (chain string
                (match master-regex)
                (for-each handle-token))
         
         (if (> parse-stack.length 1)
             (error "unexpected EOF, probably missing a )\n"
                    (call inspect (first parse-stack))))
         tokens)))

(force-semi)

(def indent (&rest args)
  (+ (chain (compact args)
            (join "\n")
            (replace /^/ "\n")
            (replace /\n/g "\n  "))
     "\n"))

(def construct-hash (array-of-arrays)
  (inject {} array-of-arrays
          (fn (object item)
            (set object (first item) (get object (second item)))
            object)))

(var= macros (hash))
(set sibilant 'macros macros)

(set macros 'return
     (fn (token)
       (var= default-return
             (+ "return " (translate token)))
         
       (if (array? token)
            (switch (first token)
              ('(return throw do)
               (translate token))
              ('delete
               (var= delete-macro (get macros 'delete))
               (if (< token.length 3)
                    default-return
                   (+ (apply delete-macro (token.slice 1 -1))
                      "\nreturn "
                      (delete-macro (last token)))))
              ('=
               (if (< token.length 4) default-return
                    (+ (apply (get macros '=)
                              (token.slice 1 (- token.length 2)))
                       "\nreturn "
                       (apply (get macros '=)
                              (token.slice -2)))))
              ('set
               (if (< token.length 5) default-return
                    (do (var= obj             (second token)
                              non-return-part (token.slice 2 (- token.length 2))
                              return-part     (token.slice -2))
                        (non-return-part.unshift obj)
                        (return-part.unshift obj)
                        (+ (apply macros.set
                                  non-return-part)
                           "\nreturn "
                           (apply macros.set
                                  return-part)))))
              (default default-return))
            default-return)))

(def macros.statement (&rest args)
  (+ (apply macros.call args) ";\n"))

(def macros.do (&rest body)
  (var= last-index
        (-math.max 0 (- body.length 1)))
  (set body last-index
       ['return (get body last-index)])
  (join "\n"
        (map body (fn (arg)
                    (+ (translate arg) ";")))))

(def macros.call (f-name &rest args)
  (+ (translate f-name)
     "(" (join ", " (map args translate)) ")"))

(def macros.def (f-name &rest args-and-body)
  (var= f-name-tr (translate f-name)
        start     (if (/\./ f-name-tr) "" "var "))
  (+ start f-name-tr " = "
     (apply macros.fn args-and-body)
     ";\n"))

(def macros.mac (name &rest args-and-body)
  (var= js   (apply macros.fn args-and-body)
        name (translate name))
  (try (set macros name (eval js))
       (error (+ "error in parsing macro "
                 name ":\n" (indent js))))
  undefined)

(def macros.concat (&rest args)
  (concat "(" (join " + " (map args translate)) ")"))

(= (get macros '+)
   (fn (&rest args)
     (+ "(" (join " + " (map args translate)) ")")))

(def transform-args (arglist)
  (var= last undefined  args [])
  (each (arg) arglist
    (if (== (first arg) "&")
         (= last (arg.slice 1))
        (do (args.push [ (or last 'required) arg ])
            (= last null))))
  (if last
      (error (+ "unexpected argument modifier: " last)))
  args)

(def macros.reverse (arr)
  (var= reversed [])
  (each (item) arr
    (reversed.unshift item))
  reversed)

(var= reverse macros.reverse)

(def build-args-string (args rest)
  (var= args-string    ""
        optional-count 0)

  (each (arg option-index) args
    (if (== (first arg) 'optional)
        (= args-string
           (+ args-string
              "if (arguments.length < "
              (- args.length optional-count) ")"
              " // if " (translate (second arg)) " is missing"
              (indent
               (+ "var "
                  (chain
                    (map (args.slice (+ option-index 1))
                         (fn (arg arg-index)
                           (+ (translate (second arg)) " = "
                              (translate (second (get args
                                                      (+ option-index
                                                         arg-index)))))))
                    (reverse)
                    (concat (+ (translate (second arg)) " = undefined"))
                    (join ", "))
                  ";"))))
      (++ optional-count)))

  (if (defined? rest)
      (+ args-string
         "var " (translate (second rest))
         " = Array.prototype.slice.call(arguments, "
         args.length ");\n")
      args-string))

(def build-comment-string (args)
  (if (empty? args)
       ""
      (+ "// "
         (join " "
               (map args
                    (fn (arg)
                      (+ (translate (second arg)) ":" (first arg))))))))

;; brain 'splode
(def macros.fn (arglist &rest body)
  (var= args (transform-args arglist)
        rest (first (select args
                            (fn (arg)
                              (== 'rest (first arg)))))
        doc-string undefined)

  (set body (- body.length 1)
       ['return
        (get body (- body.length 1))])

  (if (and (== (typeof (first body)) 'string)
             (send (first body) match /^".*"$/))
      (= doc-string
         (+ "/* " (eval (body.shift)) " */\n")))

  (var= no-rest-args   (if rest (args.slice 0 -1) args)
        args-string    (build-args-string no-rest-args rest)
        comment-string (build-comment-string args))

  (+ "(function("
     (join ", " (map args (fn (arg) (translate (second arg)))))
     ") {"
     (indent comment-string doc-string args-string
             (join "\n"
                   (map body
                        (fn (stmt)
                          (+ (translate stmt) ";")))))
     "})"))

(def macros.quote (item)
  (if (== "Array" item.constructor.name)
       (+ "[ " (join ", " (map item macros.quote)) " ]")
      (if (== 'number (typeof item))
           item
          (+ "\"" (literal item) "\""))))

(def macros.hash (&rest pairs)
  (when (odd? pairs.length)
    (error (+ "odd number of key-value pairs in hash: "
              (call inspect pairs))))
  (var= pair-strings
       (bulk-map pairs (fn (key value)
                         (+ (translate key) ": "
                            (translate value)))))
  (if (>= 1 pair-strings.length)
       (+ "{ " (join ", " pair-strings) " }")
      (+ "{" (indent (join ",\n" pair-strings)) "}")))


(def literal (string)
  (inject (chain string
                 (replace /\*/g "_")
                 (replace /\?$/ "__QUERY")
                 (replace /!$/  "__BANG")
                 (replace /\+/  "__PLUS"))
          (string.match /-(.)/g)
          (fn (return-string match)
            (return-string.replace
              match
              (send (second match) to-upper-case)))))

(def translate (token hint)
  (var= hint hint)
  (if (and hint (undefined? (get macros hint)))
      (= hint undefined))
  (when (defined? token)
    (if (string? token)
        (= token (token.trim)))
    (try
     (if (array? token)
         (if (defined? (get macros (translate (first token))))
             (apply (get macros (translate (first token))) (token.slice 1))
             (apply (get macros (or hint 'call)) token))
         (if (and (string? token)
                  (token.match (regex (+ "^" sibilant.tokens.literal "$"))))
             (literal token)
             (if (and (string? token) (token.match (regex "^;")))
                 (token.replace (regex "^;+") "//")
                 (if (and (string? token) (== "\"" (first token) (last token)))
                     (chain token (split "\n") (join "\\n\" +\n\""))
                     token))))
     (error (+ e.stack "\n"
               "Encountered when attempting to process:\n"
               (indent (call inspect token)))))))


(set sibilant 'translate translate)

(def translate-all (contents)
  (var= buffer "")
  (each (token) (tokenize contents)
    (var= line (translate token "statement"))
    (if line (= buffer (+ buffer line "\n"))))
  buffer)

(set sibilant 'translate-all translate-all)
