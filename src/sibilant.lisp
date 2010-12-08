(var sibilant exports
        sys      (require 'sys)
        import   (require "sibilant/import")
        error    (lambda (str) (throw str))
        inspect  sys.inspect)

(import (require "sibilant/functional"))

(include (concat **dirname "/../src/core.lisp"))

(def include (file)
  (var fs (require 'fs)
    data (fs.read-file-sync file 'utf8))
  (translate-all data))

(set sibilant 'include include)

(def macros.include (file)
  (sibilant.include (eval (translate file))))

(def sibilant.package-info ()
  (var fs (require 'fs)
    json (meta "JSON"))
  (json.parse (fs.read-file-sync (concat **dirname "/../package.json"))))

(def sibilant.version-string ()
  (var package (sibilant.package-info)
    path (require 'path))
  (concat package.name " version " package.version
		       "\n(at " (path.join **dirname "..") ")"))

(def sibilant.version ()
  (get (sibilant.package-info) 'version))

(sibilant.include (concat **dirname "/macros.lisp"))
