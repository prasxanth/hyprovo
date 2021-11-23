#!/usr/bin/env hy

;;=========================== MACROS AND IMPORTS ===============================

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

(import [hyprovo.logger [null-logger
                             console-logger
                             file-logger
                             console-and-file-logger]])

(require [hy.extra.anaphoric [*]])

(import os)
(setv make-path (. os path join))

;;====================== FUNCTION DEFINITIONS AND TEST CASES ===================

(require [ancillaries [*]]
         [cases [*]])

(import [ancillaries [*]]
        [cases [*]])

;;=================================== TESTS ====================================

;;-------------------------------- report-result -------------------------------
(add-to-test-plan/result= "report-result-pass"
                          (report-result = (+ 1 2) 3 "Passing result")
                          True
                          "Passing output format")

(add-to-test-plan/result= "report-result-fail"
                          (report-result = (+ 1 2) 5 "Failing result")
                          False
                          "Failing output format")

;;----------------------------------- check -----------------------------------
(add-to-test-plan/result= "check"
                          (eval test-case-check)
                          (, 3 1 2)
                          "Multiple passing and failing statements")

;;------------------------------ combine-results -------------------------------
(add-to-test-plan/result= "combine-results"
                          (eval test-case-combine-results)
                          (, 6 3 3)
                          "Combine results across multiple `check` statements.")

;;--------------------------- report-combined-results --------------------------
(add-to-test-plan/result= "report-combined-results"
                          (-> (eval test-case-combine-results) (report-combined-results))
                          (, 6 3 3)
                          "Combine and report results across multiple `check` statements")

;;----------------------------------- deftest ----------------------------------

(add-to-test-plan/result= "deftest"
                          (▶ (test-add-report-combined-results))
                          (, 2 1 1)
                          "Report combined results in `check`")

(add-to-test-plan/result= "deftest-nested-and-check"
                          (▶ (test-arithmetic-1-report-combined-results))
                          (, 6 3 3)
                          "Report combined results with nested tests and checks.")

(add-to-test-plan/result= "deftest-variable-local-defs"
                          (▶ (test-sub-variable-local-defs))
                          (, 2 1 1)
                          "Variables defined locally in test body.")

;;----------------------------------- fixtures ---------------------------------

(add-to-test-plan/result= "with-fixture"
                          (▶ (with-fixture fix-a
                               (▶ (test-add-variable) (test-sub-variable))))
                          (, 4 2 2)
                          "Multiple tests with one fixture.")

(add-to-test-plan/result= "with-fixture-multiple-statements"
                          (▶ (with-fixture fix-b
                               (▶ (test-add-variable) (test-sub-variable))))
                          (, 4 1 3)
                          "Tests with fixture containing multiple statements in setup and teardown.")

(add-to-test-plan/result= "nested-with-fixture"
                          (▶ (with-fixture fix-c
                               (▶ (with-fixture fix-d
                                    (▶ (test-add-variable) (test-mul-variable))))))
                          (, 4 2 2)
                          "Multiple tests with nested fixtures.")

(add-to-test-plan/result= "with-fixtures"
                          (▶ (with-fixtures [fix-a fix-b]
                               (▶ (test-mul-variable) (test-div-variable))))
                          (, 8 2 6)
                          "Multiple tests using multiple fixtures.")

(add-to-test-plan/result= "nested-with-fixtures"
                          (▶ (with-fixtures [fix-c fix-c]
                               (▶ (with-fixtures [fix-d fix-d]
                                    (▶ (test-add-variable) (test-sub-variable))))))
                          (, 16 8 8)
                          "Multiple tests using multiple nested fixtures.")

(add-to-test-plan/result= "deftest-with-fixture"
                          (▶ (deftest-with-fixture))
                          (, 8 4 4)
                          "deftest with fixture and tests.")

(add-to-test-plan/result= "deftest-local-defs-with-fixture"
                          (▶ (deftest-local-defs-with-fixture))
                          (, 4 2 2)
                          "Values of local variables when defined within deftest should be used instead of those in the fixture.")

(add-to-test-plan/result= "deftest-partial-local-defs-with-fixture"
                          (▶ (deftest-partial-local-defs-with-fixture))
                          (, 4 2 2)
                          "Values of local variables defined within deftest should be used. Variable definitions missing should be taken from those defined in the fixture.")

;;------------------------------------ suites ----------------------------------

(add-to-test-plan/suite= "suite-check"
                         suite-check
                         (, 3 1 2)
                         "Report combined results in suite with checks.")

(add-to-test-plan/suite= "suite-deftest"
                         suite-deftest
                         (, 4 2 2)
                         "Report combined results in suite with deftests.")

(add-to-test-plan/suite= "suite-nested-deftests"
                         suite-nested-deftests
                         (, 10 5 5)
                         "Report combined results in suite with nested deftests.")

(add-to-test-plan/suite= "nested-suites"
                         nested-suites
                         (, 17 8 9)
                         "Report combined results in suite with nested suites.")

(add-to-test-plan/suite= "suite-with-fixture-in-deftest"
                         suite-with-fixture-in-deftest
                         (, 8 4 4)
                         "deftest in suite containing a fixture.")

(add-to-test-plan/suite= "suite-with-fixtures"
                         suite-with-fixtures
                         (, 8 2 6)
                         "Suite with multiple fixtures for multiple tests.")

(add-to-test-plan/suite= "suite-with-nested-fixture"
                         suite-with-nested-fixture
                         (, 4 2 2)
                         "Suite with nested fixtures running multiple tests.")

(add-to-test-plan/suite= "nested-suites-with-nested-fixtures"
                         nested-suites-with-nested-fixtures
                         (, 12 4 8)
                         "Suite with nested suites and nested fixtures.")

;;----------------------------------- Run Tests --------------------------------

(execute-test-plan)

