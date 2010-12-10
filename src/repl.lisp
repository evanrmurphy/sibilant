(var stream     (process.open-stdin)
        script     (get (process.binding 'evals) "Script")
        readline   (send (require 'readline) create-interface stream)
	sibilant   (require (concat **dirname "/sibilant"))
	context    undefined
	cmd-buffer ""
	sys        (require 'sys)
	display-prompt-on-drain false)

(def create-context ()
  (var context (script.create-context))
  (set module 'filename (concat (process.cwd) "/exec"))
  (set context 'module  module
               'require require)
  (each-key key global (set context key (get global key)))
  context)

(assign context (create-context))

(stream.on 'data (lambda (data) (readline.write data)))

(def display-prompt ()
  (readline.set-prompt
   (concat (if (> cmd-buffer.length 10)
	       (concat "..." (cmd-buffer.slice -10))
	     (if (> cmd-buffer.length 0) cmd-buffer "sibilant"))
	   "> "))
  (readline.prompt))

(readline.on 'line
     (lambda (cmd)
       (var js-line ""
	 flushed true)

       (try
	(do
	  (assign cmd-buffer (concat cmd-buffer cmd))
	  (each (stmt) (sibilant.tokenize cmd-buffer)
		(assign js-line (concat js-line
				      (sibilant.translate stmt 'statement))))
	  (var result (script.run-in-context js-line context "sibilant-repl"))
	  (set readline.history 0 cmd-buffer)
	  (when (defined? result)
	    (assign flushed
		  (stream.write (concat "result: "
					(sys.inspect result) "\n"))))
	  (set context "_" result)
	  (assign cmd-buffer ""))
	(do
	  (if (e.message.match "unexpected EOF")
	      (do (assign cmd-buffer (concat cmd-buffer " "))
		     (readline.history.shift))
	    (do (set readline.history 0 cmd-buffer)
		   (assign flushed (stream.write e.message)
			 cmd-buffer "")))))
       
       (if flushed (display-prompt)
	 (assign display-prompt-on-drain true))))

(readline.on 'close stream.destroy)

(stream.on 'drain
    (lambda ()
      (when display-prompt-on-drain
	(display-prompt)
	(assign display-prompt-on-drain false))))

(display-prompt)

	 
