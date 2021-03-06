(var= sibilant (require 'sibilant)
        path     (require 'path)
	options  (require "sibilant/options")
        fs       (require 'fs)
        script   (get (process.binding 'evals) "Script")
        context  (script.create-context))

(def create-context ()
  (= context.initialized? true)
  (set module 'filename (+ (process.cwd) "/exec"))
  (set context 'module  module
               'require require)
  (each-key key global (set context key (get global key))))

(def run-in-sandbox (js input-path)
  (when (not context.initialized?) (create-context))
  (when (defined? input-path)
    (set process.argv 1 input-path)
    (set context '**dirname (path.dirname input-path))
    (set module 'filename input-path))
  (script.run-in-context js context 'sibilant))

(defhash cli
  v         'version
  h         'help
  unhandled 'help
  i         'input
  o         'output
  x         'execute
  e         'eval
  after-break false
  execute   false
  unlabeled 'input)

(def cli.version (&rest args)
  (console.log (sibilant.version-string)))

(def cli.repl (&rest args) (require "sibilant/repl"))

(def cli.eval (&rest args)
  (if (empty? args)
      (do! (var= stdin (process.open-stdin)
                data "")
          (stdin.set-encoding "utf8")
          (stdin.on 'data (fn (chunk) (= data (+ data chunk))))
          (stdin.on 'end (fn (&rest args)
                           (run-in-sandbox (sibilant.translate-all data)))))
      (each (arg) args
        (run-in-sandbox (sibilant.translate-all arg)))))


(def cli.help (&rest args)
  (console.log
"Hi there!  Thanks for installing sibilant.
Please leave feedback on github issues (http://github.com/jbr/sibilant/issues)

The current commandline options are:
--------------------------------------------------------------------------------

-v / --version         Print out a version string and exit

-h / --help            This message

--repl / [no args]     Sibilant interactive command prompt

--eval [optional STRING] / -e [optional STRING]
                       Evaluate STRING if provided, otherwise evaluate STDIN.

--execute / -x         This is a flag. Execute input files in order supplied.

--output DIR / -o DIR  Output input files to this dir, replacing .lisp with .js.

--input FILE / -i FILE / FILE
                       Add this file to the input files. If the execute flag is
                       set, input files will be executed.  If an output dir is
                       specified, each file will be written to that dir.
                       Otherwise, each file will be written to STDOUT.


To pass arguments to an executed file, append them after a \"--\", as follows:
$ sibilant -x myfile.lisp -- --arg-for-my-program=stuff

myfile.lisp will see process.argv as
[ 'sibilant', 'myfile.lisp', '--arg-for-my-program=stuff' ]

--------------------------------------------------------------------------------

Examples

to compile sibilant
$ git clone git://github.com/jbr/sibilant.git
$ npm link .
$ sibilant src/*.lisp -o lib
$ sibilant -x test/test.lisp # you're now running a sibilant you just compiled.

to compile one file to stdout
$ sibilant test/test.lisp

to compile a file to a directory
$ sibilant test/test.lisp -o . # put test.js here
or
$ sibilant --input test/test.lisp --output .

to run a file
$ sibilant -x test/test.lisp

to enter the repl
$ sibilant
or
$ sibilant --repl

"))

(var= cli-options (options cli))

(var= args (or cli-options.after-break []))


(args.unshift (second process.argv) "FILENAME")
(set process 'argv args 'ARGV args)

(when (empty? (keys cli-options))
  (cli.repl))

(var= output-dir
  (when cli-options.output (first cli-options.output)))

(def strip-shebang (data)
  (data.replace /^#!.*\n/ ""))

(def sibilant.translate-file (file-name)
  (sibilant.translate-all (strip-shebang (fs.read-file-sync file-name "utf8"))))

(each (input-file) (or cli-options.input [])
      (var= input-path (path.join (process.cwd) input-file)
           translated (sibilant.translate-file input-path))
      
      (if output-dir
	  (do!
	    (var=
	      input-basename (path.basename input-path ".lisp")
	      output-path (+ (path.join output-dir input-basename) ".js"))
	    (fs.write-file output-path translated))
	(if cli-options.execute
	    (run-in-sandbox translated input-path)
	  (console.log translated))))
