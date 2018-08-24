#!/bin/bash

export scmbDir="$( cd -P "$( dirname "$0" )" && pwd )/../.."

# Zsh compatibility
if [ -n "${ZSH_VERSION:-}" ]; then shell="zsh"; SHUNIT_PARENT=$0; setopt shwordsplit; fi

# Load test helpers
source "$scmbDir/test/support/test_helper.sh"

# Load functions to test
source "$scmbDir/lib/scm_breeze.sh"

#-----------------------------------------------------------------------------
# Unit tests
#-----------------------------------------------------------------------------

test__safe_eval() {
  assertEquals "runs eval with simple words" "'one' 'two' 'three'" "$(_safe_eval token_quote one two three)"
  assertEquals "quotes spaces" "'a' 'b c' 'd'" "$(_safe_eval token_quote a b\ c d)"
  assertEquals "quotes special chars" "'a b' '\$dollar' '\\slash' 'c d'" "$(_safe_eval token_quote a\ b '$dollar' '\slash' c\ d)"
}


# load and run shUnit2
source "$scmbDir/test/support/shunit2"
