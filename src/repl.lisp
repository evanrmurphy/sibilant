(var= stream     (process.open-stdin)
        script     (get (process.binding 'evals) "Script")
        readline   (send (require 'readline) create-interface stream)
	sibilant   (require (+ **dirname "/sibilant"))
	context    undefined
	cmd-buffer ""
	sys        (require 'sys)
	display-prompt-on-drain false)

(def create-context ()
  (var= context (script.create-context))
  (set module 'filename (+ (process.cwd) "/exec"))
  (set context 'module  module
               'require require)
  (each-key key global (set context key (get global key)))
  context)

(= context (create-context))

(stream.on 'data (fn (data) (readline.write data)))

(def display-prompt ()
  (readline.set-prompt
   (+ (if (> cmd-buffer.length 10)
	       (+ "..." (cmd-buffer.slice -10))
	     (if (> cmd-buffer.length 0) cmd-buffer "sibilant"))
	   "> "))
  (readline.prompt))

(readline.on 'line
     (fn (cmd)
       (var= js-line ""
	 flushed true)

       (try
	(do!
	  (= cmd-buffer (+ cmd-buffer cmd))
	  (each (stmt) (sibilant.tokenize cmd-buffer)
		(= js-line (+ js-line
				      (sibilant.translate stmt 'statement))))
	  (var= result (script.run-in-context js-line context "sibilant-repl"))
	  (set readline.history 0 cmd-buffer)
	  (when (defined? result)
	    (= flushed
		  (stream.write (+ "result: "
					(sys.inspect result) "\n"))))
	  (set context "_" result)
	  (= cmd-buffer ""))
	(do!
	  (if (e.message.match "unexpected EOF")
	      (do! (= cmd-buffer (+ cmd-buffer " "))
		     (readline.history.shift))
	    (do! (set readline.history 0 cmd-buffer)
		   (= flushed (stream.write e.message)
			 cmd-buffer "")))))
       
       (if flushed (display-prompt)
	 (= display-prompt-on-drain true))))

(readline.on 'close stream.destroy)

(stream.on 'drain
    (fn ()
      (when display-prompt-on-drain
	(display-prompt)
	(= display-prompt-on-drain false))))

(display-prompt)

	 
