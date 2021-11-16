(defn run-tests [&rest tests]
  "Function to run tests (defined by `deftest`), `with-fixture` or `with-fixtures`."
  (do
    (import [hyprovo.framework :as fmwk-funcs])
    (as-> (lfor t% tests (t%)) it
          (fmwk-funcs.combine-results #* it))))

(setv ▶ run-tests) ;; alias for `run-tests` function

(defmacro defsuite [suite-name &rest body]
  "Macro that defines function to setup test environment. The function is declared with an optional `test-logger` argument (defaults to logging to console). The suite name is prepended to all tests within the suite."
  `(do
     (import [hyprovo.logger [console-logger]])
     (defn ~suite-name [&optional [test-logger console-logger]]
       (setup-test-env)
       (setv *test-logger* test-logger)
       (with [(*test-name* :value ~(str suite-name))]
         ~@body))))

(defmacro with-fixtures [fixture-names &rest tests]
  "Runs tests with each fixture in `fixture-names` and combines results.

   Fixtures must be called with the 'double parenthesis' notation, e.g., ((fixture-a)) or ((fixture-b))."
  `(fn []
     (require [hyprovo.framework :as fmwk-macros])
     (import [hyprovo.framework :as fmwk-funcs])
     (fmwk-funcs.combine-results ~@(lfor fix% fixture-names `((fmwk-macros.with-fixture ~fix% ~@tests))))))

(defmacro! with-fixture [fixture-name &rest tests]
  "Runs tests with `fixture-name` and combines results.

  Fixtures must be called with the 'double parenthesis' notation, e.g., ((fixture-a)) or ((fixture-b))."
  `(fn []
     (import [hyprovo.framework :as fmwk-funcs])
     (~fixture-name "setup")
     (setv results% [~@tests])
     (~fixture-name "teardown")
     (as-> (map tuple results%) it
           (tuple it)
           (fmwk-funcs.combine-results #* it))))

(defmacro! deffixture [fixture-name
                       &optional [setup None] [teardown None]]
  "Macro to define a test fixture. A test fixture consists of setup and teardown statements that are then applied to given test cases."
  `(defmacro ~fixture-name [&optional [env "setup"]]
     (when (= env "setup") (return '~@setup))
     (when (= env "teardown") (return '~@teardown))))

(defmacro setup-test-env []
  "Sets up test environment. Import macros and packages. Initialize *test-name* variable. This macro should be called at the start, before defining and running any test cases. Remember to call 'teardown-test-env' at the end."
  `(eval-and-compile
     (require [hyprovo.framework :as fmwk-macros])
     (import [hy.contrib.hy-repr [hy-repr]])
     (import logging
             sys
             datetime
             random
             string)
     (fmwk-macros.init-test-name)
     (fmwk-macros.init-test-logger)))

(defmacro init-test-name []
  "Initialize *test-name* variable for tests."
  `(do
     (import [xlocal :as xlcl])
     (setv *test-name* (.xlocal xlcl))))

(defmacro init-test-logger []
  "Initialize *test-logger variable for tests."
  `(do
     (import [hyprovo.logger :as logger])
     (setv *test-logger* (. logger console-logger))))

(defmacro teardown-test-env []
  "Shuts down logger and removes all test variables. This macro should be called at the end, after running all the test cases. Ensure that the 'setup-test-env' macro has been called a the beginning."
  `(do
     (setv (. *test-logger* handlers) [])
     (.shutdown logging)
     (del *test-name*)
     (del *test-logger*)))

(defmacro deftest [label &rest body]
  "A macro that returns a macro that returns an anonymous test function. Consider for example the following,

  => (deftest test-add
  ...  (check (= (+ a b) 3 add pass”))

  Then,

  => (setv a 1 b 2)
  => (setv tester (test-add))

  defines the function `test-add` and sets the variable tester to the anonymous function returned. The variables `a` and `b` are used from the statement defined previously. Calling the tester function, (tester), will run the test.

  This construct allows the test function to use the information from the surrounding scope (LEGB). For example, if `test-add` were defined inside a function,

    => (defn arithmetic
    ...  (setv a 2 b 1)
    ...  (setv tester (test-add))
    ...  (tester))

  then the variables `a` and `b` defined in the local scope will be used since the function is also 'defined' in the same scope. The `test-add` function can be *simultaneously* defined and executed at point of call using the 'double parenthesis' notation. So the arithmetic function above could have been written as,

  => (defn arithmetic
       ...  (setv a 5 b 10)
       ...  ((test-add)))

  The first set of parenthesis defines the function and the second set call the returned anonymous function.

  This is especially useful when the same function needs to be used in either global or local context with (variable) values used from the appropriate scope!

    deftest definitions can be nested.

    See tests and documentation for more examples."
    `(defmacro ~label []
     '(fn []
        (try
          (with [(*test-name* :value (+ (. *test-name* value) " / " ~(str label)))]
            ~@body)
          (except [AttributeError]
            (with [(*test-name* :value ~(str label))]
              ~@body))))))

(defmacro check [&rest forms]
  "Run each expression in 'forms' as a test case."
  `(do
     (require [hyprovo.framework :as fmwk-macros])
     (import [hyprovo.framework :as fmwk-funcs])
     (fmwk-funcs.summarize-results
       ~@(lfor f forms `(fmwk-macros.report-result ~@f)))))

(eval-and-compile
  (defn summarize-results [&rest results]
    "Aggregates total, pass and fail counts of test results. Called by `check`."
    (do
      (setv results% (-> (map int results) (list)))
      (setv total% (len results%)
            pass% (sum results%)
            fail% (- total% pass%))
      (, total% pass% fail%))))

(eval-and-compile
  (defn combine-results [&rest results]
    "Combine the total, pass and fail counts from test results."
    (do
      (setv total% 0 pass% 0 fail% 0)
      (for [[t p f] results]
        (setv total% (+ total% t)
              pass% (+ pass% p)
              fail% (+ fail% f)))
      (, total% pass% fail%))))

(defmacro! report-combined-results [results]
  "Report the combined results from a group of test cases."
  `(do
     (setv [~g!total% ~g!pass% ~g!fail%] ~results)
     (try
       (. *test-name* value)
       (setv ~g!test-name% (+ "(" (. *test-name* value) "):"))
       (except [AttributeError]
         (setv ~g!test-name% "")))
     (->> (.format "{} Test Summary → Total: {}    Pass: {}    Fail: {}"
                   ~g!test-name% ~g!total% ~g!pass% ~g!fail%) (.debug *test-logger*))
     (, ~g!total% ~g!pass% ~g!fail%)))

(defmacro! report-result [op expr expected description]
  "Report the results of a single test case. Called by 'check'."
  `(do
     (require [hyprovo.framework :as fmwk-macros])
     (setv ~g!result% (~op ~expr ~expected))
     (try
       (. *test-name* value)
       (setv ~g!test-name% (+ "(" (. *test-name* value) "):"))
       (except [AttributeError]
         (setv ~g!test-name% "")))

     (setv ~g!indent% (* " " 36))
     (if ~g!result%
         (->> (.format "Pass ✓... {} {}" ~g!test-name% ~description) (.info *test-logger*))
         (->> (.format "Fail ✗... {} {} \n{}Expected: {}\n{}Got: {}"
                       ~g!test-name% ~description ~g!indent%
                       (fmwk-macros.stringify ~expected) ~g!indent%
                       (fmwk-macros.stringify ~expr))
              (.error *test-logger*)))

     ~g!result%))

(defmacro stringify [expr]
  "Convert expression to string; Remove quote from string returned by 'hy-repr'. Called by 'report-result'."
  `(.replace (hy-repr ~expr) "'" ""))
