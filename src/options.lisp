(var= import (require "sibilant/import"))

(import (require "sibilant/functional"))

(def extract-options (config args)
  (var= args (or args (process.argv.slice 2))
    default-label 'unlabeled
    current-label default-label
    after-break false
    config (or config {})
    unlabeled [])

  (def label? (item) (and (string? item) (send /^-/ test item)))

  (def synonym-lookup (item)
    (var= config-entry (get config item))
    (if (string? config-entry)
	(synonym-lookup config-entry)
      item))

  (def takes-args? (item)
    (!= false (get config (label-for item))))

  (= default-label (synonym-lookup default-label)
	current-label default-label)

  (def label-for (item)
    (synonym-lookup (item.replace /^-+/ "")))

  (def add-value (hash key value)
    (var= current-value (get hash key))
    (when (undefined? current-value)
      (= current-value [])
      (set hash key current-value))
    (when (!= true value)
      (current-value.push value)))

  (def reset-label ()
    (= current-label default-label))

  (inject {} args
    (fn (return-hash item index)
      (if (== "--" item)
          (= after-break true)
          (if after-break
              (add-value return-hash 'after-break item)
              (if (label? item)
                  (do! (= current-label (label-for item))
                       (add-value return-hash current-label true)
                       (when (not (takes-args? item)) (reset-label)))
                  (do! (add-value return-hash current-label item)
                       (reset-label)))))
      return-hash)))

(def process-options (config)
  (var= options (extract-options config))
  (when config
    (def handle-pair (key value)
       (var= handle (get config key))
       (when (string? handle) (handle-pair handle value))
       (when (function? handle) (apply handle value)))
     (send (keys options) for-each
	   (fn (key) (handle-pair key (get options key)))))

  options)
    
(set module 'exports process-options)
