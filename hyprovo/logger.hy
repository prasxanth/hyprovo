(import logging
        sys
        os)

(defn generate-random-string [&optional [length 9]]
  "Generate random alphanumeric string of given `length`."
  (import random string)
  (->> (. string ascii-uppercase)
       (+ (. string digits))
       (.choices random :k length)
       (.join "")))

(defn formatter [&optional
                 ^(of str) [fmt  "%(asctime)s.%(msecs)03d - %(levelname)s - %(message)s"]
                 ^(of str) [datefmt "%Y-%m-%d %H:%M:%S"]]
  "Initializes logging formatter."
  (return (.Formatter logging :fmt fmt :datefmt datefmt)))

(defn add-null-handler! [^(of logging.Logger) test-logger]
  "Adds a 'do-nothing' null handler to `test-logger` object. Mutates `test-logger`."
  (.addHandler test-logger (.NullHandler logging)))

(defn add-stream-handler! [^(of logging.Logger) test-logger
                           ^(of logging.Formatter) formatter
                           &optional ^(of int) [level logging.DEBUG]]
  "Adds a stream (console) handler to `test-logger` object. Mutates `test-logger`."
  (setv logging-stdout-handler% (.StreamHandler logging sys.stdout))
  (.setLevel logging-stdout-handler% level)
  (.setFormatter logging-stdout-handler% formatter)
  (.addHandler test-logger logging-stdout-handler%)
  (return test-logger))

(defn add-file-handler! [^(of logging.Logger) test-logger ^(of str) filename
                         ^(of logging.Formatter) formatter
                         &optional ^(of int) [level logging.DEBUG]]
  "Adds a file handler to `test-logger` object with `filename`. Mutates `test-logger`."
  (setv logging-file-handler% (.FileHandler logging filename))
  (.setLevel logging-file-handler% level)
  (.setFormatter logging-file-handler% formatter)
  (.addHandler test-logger logging-file-handler%)
  (return test-logger))

(defn init-logger [&optional ^(of int) [level logging.DEBUG]]
  "Initializes a test logger object."
  (setv logger-name% (generate-random-string))
  (setv test-logger% (.getLogger logging logger-name%))

  (.setLevel test-logger% level)
  (setv (. test-logger% propagate) False)

  (return test-logger%))


;; Default Loggers
(setv null-logger (-> (init-logger) (add-null-handler!)))

(setv console-logger (-> (init-logger) (add-stream-handler! :formatter (formatter))))

(defn delete-file-if-exists [^(of str) filename]
  "Deletes file if it exists on disk."
  (unless (none? filename)
    (try
      (.remove os filename)
      (except [] (print "File does not exist")))))

(defn file-logger [^(of str) log-file &optional ^(of bool) [append False]]
  (unless append
    (delete-file-if-exists log-file))
  (-> (init-logger) (add-file-handler! :formatter (formatter) :filename log-file)))

(defn console-and-file-logger [^(of str) log-file
                               &optional ^(of bool) [append False]]
  (unless append
    (delete-file-if-exists log-file))
  (-> (init-logger)
      (add-stream-handler! :formatter (formatter))
      (add-file-handler! :formatter (formatter) :filename log-file)))

