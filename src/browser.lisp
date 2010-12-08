(scoped
 (defvar sibilant (list))
 (def error (str) (throw (new (-error str))))
 (def inspect (item) (if item.to-source (item.to-source) (item.to-string)))
 (set window 'sibilant sibilant)

 (defvar exports (hash))
 (include (concat **dirname "/../src/functional.lisp"))
 (include (concat **dirname "/../src/core.lisp"))

 ($ (thunk
  (defvar sibilant window.sibilant
    scripts (list))

  (def eval-with-try-catch (js)
    (try (eval js) (progn (console.log js) (throw e))))

  (def sibilant.script-loaded ()
    (defvar lisp null
      js   null)
    (when (not (sibilant.load-next-script))
      (chain ($ "script[type=\"text/lisp\"]:not([src])")
        (each (thunk
               (setf lisp (chain ($ this)
                                 (text)
                                 (replace /(^\s*\/\/\<!\[CDATA\[)|(\/\/\]\]>\s*$)/g ""
                                  ))
                     js (sibilant.translate-all lisp))

               (chain ($ this) (data 'js js))
               (eval-with-try-catch js))))))

  (setf scripts ($.make-array (chain
    ($ "script[type=\"text/lisp\"][src]") (map (thunk this.src)))))

  (def sibilant.load-next-script ()
    (defvar next-script (scripts.shift))
    (when (defined? next-script)
      ($.get next-script (lambda (data)
                           (eval-with-try-catch  (sibilant.translate-all data))
                           (sibilant.script-loaded)))
      true))

  (sibilant.load-next-script))))
