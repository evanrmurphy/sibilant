(scoped
 (var= sibilant [])
 (def error (str) (throw (new (-error str))))
 (def inspect (item) (if item.to-source (item.to-source) (item.to-string)))
 (set window 'sibilant sibilant)

 (var= exports {})
 (include (+ **dirname "/../src/functional.lisp"))
 (include (+ **dirname "/../src/core.lisp"))

 ($ (thunk
  (var= sibilant window.sibilant
    scripts [])

  (def eval-with-try-catch (js)
    (try (eval js) (do! (console.log js) (throw e))))

  (def sibilant.script-loaded ()
    (var= lisp null  js null)
    (when (not (sibilant.load-next-script))
      (chain ($ "script[type=\"text/lisp\"]:not([src])")
        (each (thunk
               (= lisp (chain ($ this)
                                 (text)
                                 (replace /(^\s*\/\/\<!\[CDATA\[)|(\/\/\]\]>\s*$)/g ""
                                  ))
                     js (sibilant.translate-all lisp))

               (chain ($ this) (data 'js js))
               (eval-with-try-catch js))))))

  (= scripts ($.make-array (chain
    ($ "script[type=\"text/lisp\"][src]") (map (thunk this.src)))))

  (def sibilant.load-next-script ()
    (var= next-script (scripts.shift))
    (when (defined? next-script)
      ($.get next-script (fn (data)
                           (eval-with-try-catch  (sibilant.translate-all data))
                           (sibilant.script-loaded)))
      true))

  (sibilant.load-next-script))))
