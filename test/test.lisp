#!/usr/bin/env sibilant -x

(var= sibilant (require "../lib/sibilant")
      sys      (require 'sys)
      passes   0
      fails    0)

(console.log (+ "Testing " (sibilant.version-string)))

(def trim (string)
  (send string trim))

(def assert-equal (expected actual message)
  (sys.print (if (== expected actual)
                  (do (++ passes) ".")
                 (do (++ fails)
                     (+ "F\n\n" (+ passes fails) ": "
                        (if message
                            (+ message "\n\n")
                            "")
                        "expected " expected "\n\nbut got " actual "\n\n")))))

(def assert-translation (sibilant-code js-code)
  (assert-equal (trim js-code)
		(trim (sibilant.translate-all sibilant-code))))

(def assert-true (&rest args)
  (args.unshift true)
  (apply assert-equal args))

(def assert-false (&rest args)
  (args.unshift false)
  (apply assert-equal args))

(def assert-deep-equal (expected actual)
  (each (item index) expected
    (assert-equal item (get actual index))))

(assert-deep-equal '(a b c) ['a 'b 'c])

(assert-translation "5"        "5")
(assert-translation "$"        "$")
(assert-translation "-10.2"    "-10.2")
(assert-translation "hello"    "hello")
(assert-translation "hi-world" "hiWorld")
(assert-translation "(Object.to-string)" "Object.toString();")
(assert-translation "1two"     "1\ntwo")
(assert-translation "t1"       "t1")
(assert-translation "JSON"     "JSON")
(assert-translation "time-zone-1"       "timeZone1")
(assert-translation "'t1"      "\"t1\"")
(assert-translation "*hello*"  "_hello_")
(assert-translation "\"this\nstring\"" "\"this\\n\" +\n\"string\"")
(assert-translation "?"   "__QUERY")
(assert-translation "??"   "__QUERY__QUERY")
(assert-translation "hello?"   "hello__QUERY")
(assert-translation "?hello"   "__QUERYhello")
(assert-translation "hello!"   "hello__BANG")
(assert-translation ":"   "__COLON")
(assert-translation "::"   "__COLON__COLON")
(assert-translation "-math"    "Math")
(assert-translation "\"string\"" "\"string\"")
(assert-translation "\"\"" "\"\"")
(assert-translation "$.make-array" "$.makeArray")
(assert-translation "($.make-array 1)" "$.makeArray(1);")

(assert-translation "/regex/"   "/regex/")

(assert-translation "(regex \"regex\")" "(new RegExp(\"regex\", undefined))")
(assert-translation "(regex \"regex\" 'g)" "(new RegExp(\"regex\", \"g\"))")

(assert-translation "(pow a b)" "Math.pow(a, b)")
(assert-translation "(++ x)"  "((x)++)")
(assert-translation "(dec x)"  "((x)--)")

(assert-translation "'hello"        "\"hello\"")
(assert-translation "(quote hello)" "\"hello\"")

(assert-translation "'(hello world)"
                    "[ \"hello\", \"world\" ]")
(assert-translation "(quote (a b c))"
                    "[ \"a\", \"b\", \"c\" ]")

; lists
(assert-translation "(list)"     "[  ]")
(assert-translation "(list a b)" "[ a, b ]")

; hashes
(assert-translation "(hash)"         "{  }")
(assert-translation "(hash a b)"     "{ a: b }")
(assert-translation "(hash a b c d)" "{\n  a: b,\n  c: d\n}")

; when
(assert-translation "(when a b)"
                    "(function() { if (a) { return b; } }).call(this)")

(assert-translation "(when a b c d)"
                    "(function() { if (a) { b; c; return d; } }).call(this)")

; if

(assert-translation "(if a b c)"
                    "(function() { if (a) { return b; } else { return c; } }).call(this)")

(assert-translation "(?: a b c)"
                    "(a ? b : c)")

; do

(assert-translation "(do a b c d e)"
                    "a; b; c; d; return e;")

; do!

(assert-translation "(do! a b c d e)"
                    "(function() { a; b; c; d; return e; }).call(this)")

; =2!

(assert-translation "(=2! x 1 y 2)"
                    "(x = 1, y = 2)")


; do2!

(assert-translation "(do2! a b c d e)"
                    "(a, b, c, d, e)")

; Not working because =2! doesn't expand in this context
; Update: it's do2!'s fault, not =2!. The problem seems
;  to be that do2! doesn't expand/evaluate its args, just
;  processes them raw. The sibilant macro system in its
;  present state seems very bare-bones.
; (assert-translation "(do2! 
;                        (=2! x 1 y 2)
;                        (alert x))"
;                     "((x = 1, y = 2), alert(x))")

; join

(assert-translation "(join \" \" (list a b c))"
                    "([ a, b, c ]).join(\" \")")

; meta

(assert-translation "(meta (+ 5 2))"
                    "7")

; comment

(assert-translation "(comment hello)" "// hello")

(assert-translation "(comment (fn () hello))"
    (+ "// (function() {\n"
	     "//   return hello;\n"
	     "// })"))

; new

(assert-translation "(new (prototype a b c))"
                    "(new prototype(a, b, c))")

(assert-translation "(thunk a b c)"
"(function() {
  a;
  b;
  return c;
})")

(assert-translation "(keys some-object)"
                    "Object.keys(someObject)")

(assert-translation "(delete (get foo 'bar))"
                    "delete (foo)[\"bar\"];")

(assert-translation "(delete (get foo 'bar) bam.bibble)"
"delete (foo)[\"bar\"];
delete bam.bibble;")

(assert-translation "(thunk (delete a.b c.d e.f))"
"(function() {
  delete a.b;
  delete c.d;
  return delete e.f;;
})")


(assert-translation "(var x)"
                    "var x;")

(assert-translation "(var a b c d)"
                    "var a, b, c, d;")

(assert-translation "(var= a b c d)"
                    "var a = b,\n    c = d;")

(assert-translation "(function? x)"
                    "typeof(x) === 'function'")

(assert-translation "(number? x)"
                    "typeof(x) === 'number'")

(assert-translation "(def foo.bar (a) (* a 2))"
"foo.bar = (function(a) {
  return (a * 2);
});")

(assert-translation "(each-key key hash a b c)"
"(function() { for (var key in hash) (function() {
  a;
  b;
  return c;
})(); }).call(this);")

(assert-translation "(scoped a b c)"
"(function() {
  a;
  b;
  return c;
})()")

(assert-translation "(arguments)" "(Array.prototype.slice.apply(arguments))")

(assert-translation "(set hash k1 v1 k2 v2)"
"(hash)[k1] = v1;
(hash)[k2] = v2;")

(assert-translation "(defhash hash a b c d)"
"var hash = {
  a: b,
  c: d
};")

(assert-translation "(each (x) arr a b c)"
"arr.forEach((function(x) {
  a;
  b;
  return c;
}))")

(assert-translation "(switch a (q 1))"
"(function() {
  switch(a) {
  case q:
    return 1;
  }
})()")

(assert-translation "(switch a ('q 2))"
"(function() {
  switch(a) {
  case \"q\":
    return 2;
  }
})()"
)
(assert-translation "(switch a ((a b) t))"
"(function() {
  switch(a) {
  case a:
  case b:
    return t;
  }
})()")

(assert-translation "(switch a ((r 's) l))"
"(function() {
  switch(a) {
  case r:
  case \"s\":
    return l;
  }
})()")

(assert-translation "(switch 1 ((1 2) 'one))"
"(function() {
  switch(1) {
  case 1:
  case 2:
    return \"one\";
  }
})()")

(assert-translation "(switch (+ 5 2) ('(u v) (wibble) (foo bar)))"
"(function() {
  switch((5 + 2)) {
  case \"u\":
  case \"v\":
    wibble(); return foo(bar);
  }
})()")


(assert-translation "(match? /regexp/ foo)" "foo.match(/regexp/)")

(assert-translation
 "(before-include)
  (include \"test/includeFile1\")
  (after-include-1)
  (include \"test/includeFile2\")
  (after-include-2)"

"beforeInclude();

1

afterInclude1();

2

afterInclude2();")

(assert-equal 2 (switch 'a ('a 1 2)))
(assert-equal 'default (switch 27 ('foo 1) (default 'default)))
(assert-equal undefined (switch 10 (1 1)))
(assert-equal 'hello (switch (+ 5 2)
			     ((1 7) (+ 'he 'llo))
			     (7 "doesn't match because it's second")
			     (default 10)))

(assert-translation "(thunk (= b c d e))"
"(function() {
  b = c;
  return d = e;;
})")

(assert-translation "(thunk (set b c d e f))"
"(function() {
  (b)[c] = d;
  return (b)[e] = f;;
})")


(assert-translation
 "(mac foo? () 1) (foo?) (delmac foo?) (foo?)"
 "1\nfoo__QUERY();")

(assert-translation
 "(while (< i 10) (console.log 'here) (alert 'there) 'everywhere)"
 "(function() {
  var __returnValue__ = undefined;;
  while ((i < 10)) { __returnValue__ = (function() {
    console.log(\"here\");
    alert(\"there\");
    return \"everywhere\";
  })();;
  };
  return __returnValue__;
})()")


(scoped
 (var= i 0)
 (var= return-string
   (while (< i 10)
     (= i (+ i 1))
     (+ "stopped at iteration: " i)))
 (assert-equal "stopped at iteration: 10" return-string))

(assert-translation
 "(return (do (return a)))" "return a;")

(assert-translation
 "(return (do (switch a (b c))))"

"return (function() {
  switch(a) {
  case b:
    return c;
  }
})();")

(assert-translation "(== a b c)" "
(a === b &&
 a === c)")

(assert-translation "(do)" "return undefined;")




; (assert-translation "{foo : bar wibble : wam }"
; "{
;   foo: bar,
;   wibble: wam
; }")

(assert-translation "[ foo bar (baz) ]"
"[ foo, bar, baz() ]")

(assert-translation "[[] {} baz {q r s [t]}]"
"[ [  ], {  }, baz, {
  q: r,
  s: [ t ]
} ]")

; (assert-translation "{ this: is, valid: [\"json\"]}",
; "{
;   this: is,
;   valid: [ \"json\" ]
; }")


(assert-translation "(cons a [ b c d ])"
                     "[ a ].concat([ b, c, d ])")

(assert-deep-equal '(a b c d) (cons 'a '(b c d)))








(console.log (+ "\n\n"  (+ passes fails) " total tests, "
                passes " passed, " fails " failed"))
