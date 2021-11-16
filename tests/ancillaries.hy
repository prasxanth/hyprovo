;;============================== GLOBAL VARIABLES ==============================
(require [hy.extra.anaphoric [*]])

(import [hyprovo.logger [null-logger
                             console-logger
                             file-logger
                             console-and-file-logger]])

(import os)
(setv make-path (. os path join))

;;--------------------------------- Test Plan ----------------------------------

;; stores tests to be executed in list
(setv *test-plan* [])

;;----------------------------------- Logger -----------------------------------

(import [datetime [datetime]])

(defn now-str []
      "Return current timestamp as string upto precision of seconds."
      (.strftime (.now datetime) "%Y%m%d%H%M%S"))

;; the logger outputs to both console and file. The file defaults to the start
;; timestamp of each test run.
(setv *hyprovo-logger*
      (console-and-file-logger :log-file (make-path "logs" (+ (now-str) ".log"))))

;;======================= MACROS AND FUNCTION DEFINITIONS ======================

(defmacro log-actual-result [test-name &rest body]
  "Macro returns a function which sets up the test environment. The returned function takes an optional `test-logger` as an argument (defaults to logging to the console)."
  `(defn ~test-name [&optional [test-logger console-logger]]
     (setup-test-env)
     (setv *test-logger* test-logger)
     ~@body))

(defn contains-timestamp? [^(of str) line]
  "Identifies if a given log statement contains a timestamp. Any log statement that contains the INFO, ERROR or DEBUG keywords is assumed to contain a timestamp."
    (-> (map #%(in %1 line) ["INFO" "ERROR" "DEBUG"]) (any)))

(defn read-log [^(of str) log-file &optional ^(of bool) [strip-timestamps True]]
  "Reads a log file and optionally strips the timestamps. Stripping timestamps is useful for comparing log files generated at different times."
    (with [file (open log-file)]
          (setv result% (.readlines file)))

    (setv logs [])
    (for [r% result%]
        (if (and strip-timestamps (contains-timestamp? r%))
            (.append logs (cut r% 26))
            (.append logs r%)))

    (return logs))

(defmacro! report [label description expr]
  "Macro that writes a formatted pass/fail statement to the (global) logger based on the results of expression `expr`. The label and description parameters are used to provide more information for the case under test."
    `(do
      (if ~expr
          (do
           (setv ~g!report% (, 1 1 0)) ; total, pass, fail
           (->> (.format "✓ Pass: {} - {}" ~label ~description) (.info *hyprovo-logger*)))
          (do
           (setv ~g!report% (, 1 0 1)) ; total, pass, fail
           (->> (.format "✗ Fail: {} - {}" ~label ~description) (.error *hyprovo-logger*))))
      ~g!report%))

(defmacro! validate-logs [label description]
  "Macro to compare test logs (actual vs expected). The label and description parameters are used as inputs to the `report` macro."
    `(do
      (setv ~g!actual% (make-path "results" "actual" (.format "{}.txt" ~label))
            ~g!expected% (make-path "results" "expected" (.format "{}.txt" ~label))
            ~g!test% (= (read-log ~g!actual%) (read-log ~g!expected%)))
      (report ~label ~description ~g!test%)))

(defn sum-results [results]
  "Sum corresponding elements from (nested) collection."
    (as-> (zip #* results) it
          (map sum it)
          (tuple it)))

(defn compare-logs-and-return-value [label actual expected description]
  "Template function to compare (1) actual vs expected logs and (2) return value of function. Results from (1) and (2) are combined and returned."
  (setv log-file% (make-path "results" "actual" (.format "{}.txt" label)))

  ;; compare log output
  (setv actual% (actual :test-logger (file-logger :log-file log-file%)))
  (setv result-log% (validate-logs label description))

  ;; compare return value
  (setv results% (= expected actual%))
  (setv result-return% (report label "Return value" results%))

  ;; combine results
  (sum-results (, result-log% result-return%)))

;;------- report-result, check, deftest, with-fixture and with-fixtures --------

(defmacro generate-test-case/result= [label actual expected description]
  "Macro that returns an anonymous function to generate test case and compare results (logs and return values). This is used to test `report-result`, `check`, `deftest`, `with-fixture` and `with-fixtures`."
   `(fn []
          (log-actual-result test% ~actual)
          (compare-logs-and-return-value ~label test% ~expected ~description)))

(defmacro add-to-test-plan/result= [label actual expected description]
  "Generate a test case and add it to the *test-plan* global variable."
          `(.append *test-plan* (generate-test-case/result= ~label ~actual ~expected ~description)))

;;----------------------------------- Suites -----------------------------------

(defmacro generate-test-case/suite= [label actual expected description]
  "Macro that returns an anonymous function to generate test case and compare results (log and return values) for suites (functions returned by `defsuite`)."
  `(fn []
     (compare-logs-and-return-value ~label ~actual ~expected ~description)))

(defmacro add-to-test-plan/suite= [label actual expected description]
  "Generate a test case for a suite and add it to the *test-plan* global variable."
  `(.append *test-plan* (generate-test-case/suite= ~label ~actual ~expected ~description)))

;;---------------------------------- Run tests ---------------------------------

(defn execute-test-plan []
  "Runs all tests in global *test-plan* variable. Sums results from each tests and outputs result to logger."
  (as-> (sum-results (map #%(%1) (distinct *test-plan*))) it
      (if (= (get it 2) 0)
          (->> (.format "All {} tests PASSED" (get it 0)) (.debug *hyprovo-logger*))
          (->> (.format "{}/{} tests FAILED" (get it 2) (get it 0)) (.debug *hyprovo-logger*)))))
