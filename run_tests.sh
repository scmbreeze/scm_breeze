#!/bin/sh
# Run SCM Breeze shUnit2 tests

failed=false

# allow list of shells to run tests in to be overriden by environment variable
# if empty or null, use defaults
if [ -z "$TEST_SHELLS" ]; then
  TEST_SHELLS="bash zsh"
fi

echo "== Will run all tests with following shells: ${TEST_SHELLS}"
for test in $(find test/lib -name *_test.sh); do
  for shell in $TEST_SHELLS; do
    echo "== Running tests with [$shell]: $test"
    $shell $test || failed=true
  done
done

if [ "$failed" = "true" ]; then
  echo "Tests failed!"
  false
else
  echo "All tests passed!"
  true
fi
