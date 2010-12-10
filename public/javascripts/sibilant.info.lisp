(mac trim (item)
  (macros.send item 'replace "/^\\s*|\\s*$/g" "\"\""))

(mac contains? (item arr)
  ((get macros "!=") -1 (macros.send (translate arr) 'index-of item)))


($ (thunk
    (var $window ($ window))

    (def check-hash ()
      (when (defined? check-hash.timeout)
	(clear-timeout check-hash.timeout)
	(delete check-hash.timeout))

      
      (when (!= window.location.hash ($window.data 'last-hash))
        (chain $window
          (data 'last-hash window.location.hash)
          (trigger 'hash-change window.location.hash)))

      (assign check-hash.timeout (set-timeout check-hash 500)))
    
    (var items ($ "script[language=sibilant/example]"))

    ($window.click (thunk (set-timeout check-hash 25)))

    ($window.bind 'hash-change
                  (lambda (evt hash)
                    (var item (send items filter hash))
                    (when (< 0 item.length)
                      (var content (chain item
                                             (text)
                                             (replace "<![CDATA[\n", "")
                                             (replace "]]>" "")))
                      (var title (send item attr "data-title"))
                      (send ($ "header h2") html title)
                      (var next (send item next items.selector))
                      (var prev (send item prev items.selector))
                      
                      (if (> next.length 0)
                          (chain ($ "#next")
                                 (attr 'href (concat "#" (send next attr 'id)))
                                 (show))
                        (send ($ "#next") hide))
                      
                      (if (> prev.length 0)
                          (chain ($ "#prev")
                                 (attr 'href (concat "#" (send prev attr 'id)))
                                 (show))
                        (send ($ "#prev") hide))

                      (chain ($ "textarea")
                             (val (trim content))
                             (keyup)))))


    (switch window.location.hash
            (("" "#")
             (assign window.location.hash
                   (chain items (first) (attr 'id)))))

    (var textarea ($ 'textarea))

    (chain textarea
	   (focus)
	   (keyup (lambda (evt)
                    (var output ($ "#output"))
		    (try (chain output
				(text (sibilant.translate-all (textarea.val)))
				(remove-class 'error))
			 (chain output
				(text e.stack)
				(add-class 'error))))))
    (check-hash)))


