#!/bin/sh
# Run SCM Breeze shUnit2 tests

failed=false

for test in $(find test/lib -name *_test.sh); do
  for shell in bash zsh; do
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
