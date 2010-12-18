(var= sibilant exports
        sys      (require 'sys)
        import   (require "sibilant/import")
        error    (fn (str) (throw str))
        inspect  sys.inspect)

(import (require "sibilant/functional"))

(include (+ **dirname "/../src/core.lisp"))

(def include (file)
  (var= fs (require 'fs)
    data (fs.read-file-sync file 'utf8))
  (translate-all data))

(set sibilant 'include include)

(def macros.include (file)
  (sibilant.include (eval (translate file))))

(def sibilant.package-info ()
  (var= fs (require 'fs)
    json (meta "JSON"))
  (json.parse (fs.read-file-sync (+ **dirname "/../package.json"))))

(def sibilant.version-string ()
  (var= package (sibilant.package-info)
    path (require 'path))
  (+ package.name " version " package.version
		       "\n(at " (path.join **dirname "..") ")"))

(def sibilant.strip-shebang (data)
  (data.replace /^#!.*\n/ ""))

(def sibilant.translate-file (file-name)
  (var= fs (require 'fs))
  (sibilant.translate-all
   (sibilant.strip-shebang
    (fs.read-file-sync file-name "utf8"))))

(def sibilant.version ()
  (get (sibilant.package-info) 'version))

(sibilant.include (+ **dirname "/macros.lisp"))
