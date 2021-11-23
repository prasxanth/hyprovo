(require [hyprovo.framework [setup-test-env
                                 teardown-test-env
                                 report-result
                                 check
                                 report-combined-results
                                 deffixture
                                 with-fixture
                                 with-fixtures
                                 deftest
                                 defsuite]])

(import [hyprovo.framework [combine-results run-tests ▶]])

;;=================================== check ====================================

(setv test-case-check '(check
                         (= (+ 1 2) 3 "add pass")
                         (= (- 2 3) 4 "sub fail")
                         (= (/ 10 2) 3 "div fail")))

;;=============================== combine-results ==============================

(setv test-case-combine-results '(combine-results
                                   (check
                                     (= (+ 1 2) 3 "add pass")
                                     (= (- 2 3) 4 "sub fail")
                                     (= (* 7 2) 14 "mul pass"))
                                   (check
                                     (= (/ 4 2) 2 "div pass")
                                     (= (+ 2 3) -6 "add fail")
                                     (= (* 10 2) 3 "mul fail"))))

;;=================================== deftest ==================================

(deftest test-add-report-combined-results
  (-> (check
    (= (+ 1 2) 3 "add pass")
    (= (+ 2 3) 4 "add fail"))
      (combine-results)
      (report-combined-results)))

(deftest test-add
  (check
    (= (+ 1 2) 3 "add pass")
    (= (+ 2 3) 4 "add fail")))

(deftest test-add-variable
  (check
    (= (+ a b) 2 "add pass")
    (= (+ a b) 3 "add fail")))

(deftest test-add-variable-local-defs
  (setv a 5 b 10)
  (check
    (= (+ a b) 15 "add pass")
    (= (+ a b) 3 "add fail")))

(deftest test-add-variable-partial-local-defs
  (setv c 1)
  (check
    (= (+ a b c) 3 "add pass")
    (= (+ a b c) 3 "add fail")))

(deftest test-sub
  (check
    (= (- 2 2) 0 "sub pass")
    (= (- 2 3) 4 "sub fail")))

(deftest test-sub-variable
  (check
    (= (- a a) 0 "sub pass")
    (= (- a b) 4 "sub fail")))

(deftest test-sub-variable-local-defs
  (setv a 8 b 10)
  (check
    (= (- a b) -2 "sub pass")
    (= (- a b) 7 "sub fail")))

(deftest test-sub-variable-partial-local-defs
  (setv c 3)
  (check
    (= (- a b c) -3 "add pass")
    (= (- a b c) -19 "add fail")))

(deftest test-mul
 (check
   (= (* 1 2) 2 "mul pass")
   (= (* 2 3) 4 "mul fail")))

(deftest test-mul-variable
 (check
   (= (* a b) 1 "mul pass")
   (= (* a b) 4 "mul fail")))

(deftest test-mul-variable-local-defs
  (setv a 2 b 7)
  (check
    (= (* a b) 14 "mul pass")
    (= (* a b) -5 "mul fail")))

(deftest test-mul-variable-partial-local-defs
  (setv c 2)
  (check
    (= (* a b c) 2 "mul pass")
    (= (* a b c) -3 "mul fail")))

(deftest test-div
  (check
    (= (/ 2 1) 2 "div pass")
    (= (/ 2 3) 4 "div fail")))

(deftest test-div-variable
  (check
    (= (/ b a) 1 "div pass")
    (= (/ a b) 4 "div fail")))

(deftest test-div-variable-local-defs
  (setv a 3 b 6)
  (check
    (= (/ b a) 2 "div pass")
    (= (/ a b) 3 "div fail")))

(deftest test-div-variable-partial-local-defs
  (setv c 1)
  (check
    (= (/ b a c) 1.0 "div pass")
    (= (/ a b c) 11.3 "div fail")))

(deftest test-arithmetic-1-report-combined-results
        (-> (combine-results
             (▶ (test-sub) (test-div))
               (check
                    (= (+ 1 1) 2 "add pass")
                    (= (- 0 1) 2 "sub fail")))
            (report-combined-results)))

(deftest test-arithmetic-2-report-combined-results
        (-> (▶ (test-add) (test-mul))
            (report-combined-results)))

(deftest test-arithmetic-variable-local-defs
        (-> (▶ (test-sub-variable-local-defs)
               (test-mul-variable-local-defs))
            (report-combined-results)))

;;================================== fixtures ==================================

(deffixture fix-a ((setv a 1 b 1)) ((del a b)))
(deffixture fix-b ((setv a 2) (setv b 3)) ((del a) (del b)))
(deffixture fix-c ((setv a 1)) (None))
(deffixture fix-d ((setv b 1)) (None))

(deftest deftest-with-fixture
  (-> (combine-results
        (▶ (with-fixture fix-a (▶ (test-add-variable) (test-sub-variable))))
        (▶ (test-mul) (test-div)))
      (report-combined-results)))

(deftest deftest-local-defs-with-fixture
  (-> (combine-results
        (▶ (with-fixture fix-a
             (▶ (test-add-variable-local-defs)
                (test-div-variable)))))
      (report-combined-results)))

(deftest deftest-partial-local-defs-with-fixture
  (-> (combine-results
        (▶ (with-fixture fix-a
             (▶ (test-sub-variable-partial-local-defs)
                (test-mul-variable-partial-local-defs)))))
      (report-combined-results)))

;;================================== suites ====================================

(defsuite suite-check
  (-> (combine-results
        (check
          (= (+ 1 2) 3 "add pass")
          (= (- 2 3) 4 "sub fail")
          (= (/ 10 2) 3 "div fail")))
      (report-combined-results)))

(defsuite suite-deftest
  (-> (combine-results
        (▶ (test-add) (test-sub)))
      (report-combined-results)))

(defsuite suite-nested-deftests
  (-> (combine-results
        (▶ (test-arithmetic-1-report-combined-results)
           (test-arithmetic-2-report-combined-results)))
      (report-combined-results)))

(defsuite nested-suites
  (-> (combine-results
        (suite-check :test-logger test-logger)
        (suite-deftest :test-logger test-logger)
        (suite-nested-deftests :test-logger test-logger))
      (report-combined-results)))

(defsuite suite-with-fixture-in-deftest
  (-> (combine-results
        (▶ (deftest-with-fixture)))))

(defsuite suite-with-fixture-in-deftest
  (-> (combine-results
        (▶ (deftest-with-fixture)))))

(defsuite suite-with-fixtures
  (-> (combine-results
        (▶ (with-fixtures [fix-a fix-b]
             (▶ (test-mul-variable)
                (test-div-variable)))))))

(defsuite suite-with-nested-fixture
  (▶ (with-fixture fix-c
       (▶ (with-fixture fix-d
            (▶ (test-add-variable)
               (test-mul-variable)))))))

(defsuite nested-suites-with-nested-fixtures
  (-> (combine-results
        (suite-with-fixtures :test-logger test-logger)
        (suite-with-nested-fixture :test-logger test-logger))
      (report-combined-results)))

