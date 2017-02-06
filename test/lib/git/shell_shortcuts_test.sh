#!/bin/bash
# ------------------------------------------------------------------------------
# SCM Breeze - Streamline your SCM workflow.
# Copyright 2011 Nathan Broadbent (http://madebynathan.com). All Rights Reserved.
# Released under the LGPL (GNU Lesser General Public License)
# ------------------------------------------------------------------------------
#
# Unit tests for shell command wrapping

export scmbDir="$( cd -P "$( dirname "$0" )" && pwd )/../../.."

# Zsh compatibility
if [ -n "${ZSH_VERSION:-}" ]; then
  shell="zsh"; SHUNIT_PARENT=$0; setopt shwordsplit
else
  # Bash needs this option so that 'alias' works in a non-interactive shell
  shopt -s expand_aliases
fi

# Load test helpers and core functions
source "$scmbDir/test/support/test_helper.sh"
source "$scmbDir/lib/scm_breeze.sh"

# Setup
#-----------------------------------------------------------------------------
oneTimeSetUp() {
  export shell_command_wrapping_enabled="true"
  export scmb_wrapped_shell_commands="not_found cat rm cp mv ln cd sed"
  export shell_ls_aliases_enabled="true"

  alias rvm="test" # Ensure tests run if RVM isn't loaded but $HOME/.rvm is present

  # Test functions
  function ln() { ln $@; }
  # Test aliases
  alias mv="nocorrect $(which mv)"
  alias rm="$(which rm) --option"
  alias sed="$(which sed)"
  # Test already wrapped commands
  alias cat="exec_scmb_expand_args $(which cat)"

  # Run shortcut wrapping
  source "$scmbDir/lib/git/shell_shortcuts.sh"

  # Define 'whence' function for Bash.
  # Must come after sourcing shell_shortcuts
  type whence > /dev/null 2>&1 || function whence() { type "$@" | sed -e "s/.*is aliased to \`//" -e "s/'$//"; }
}

# Helper function to test that alias is defined properly.
# (Works for both zsh and bash)
assertAliasEquals(){
  assertEquals "$1" "$(whence $2)"
}


#-----------------------------------------------------------------------------
# Unit tests
#-----------------------------------------------------------------------------

test_shell_command_wrapping() {
  assertAliasEquals "exec_scmb_expand_args $(which rm) --option"  "rm"
  assertAliasEquals "exec_scmb_expand_args nocorrect $(which mv)" "mv"
  assertAliasEquals "exec_scmb_expand_args $(which sed)"          "sed"
  assertAliasEquals "exec_scmb_expand_args $(which cat)"          "cat"
  assertAliasEquals "exec_scmb_expand_args builtin cd"            "cd"
  assertIncludes    "$(declare -f ln)" "ln ()"
  assertIncludes    "$(declare -f ln)" "exec_scmb_expand_args __original_ln"
}

test_ls_with_file_shortcuts() {
  export git_env_char="e"

  TEST_DIR=$(mktemp -d -t scm_breeze.XXXXXXXXXX)
  cd $TEST_DIR
  touch 'test file' 'test_file'
  mkdir -p "a [b]" 'a "b"' "a 'b'"
  touch "a \"b\"/c"

  # Run command in shell, load output from temp file into variable
  # (This is needed so that env variables are exported in the current shell)
  temp_file=$(mktemp -t scm_breeze.XXXXXXXXXX)
  ls_with_file_shortcuts > $temp_file
  ls_output=$(<$temp_file strip_colors)

  # Compare as fixed strings (F), instead of regex (P)
  assertIncludes "$ls_output" '[1]  a "b"' F
  assertIncludes "$ls_output" "[2]  a 'b'" F
  assertIncludes "$ls_output" '[3]  a [b]' F
  assertIncludes "$ls_output" '[4]  test file' F
  assertIncludes "$ls_output" '[5]  test_file' F

  # Test filenames with single or double quotes escaped
  assertEquals "$TEST_DIR/"'a "b"'   "$e1"
  assertEquals "$TEST_DIR/a 'b'"     "$e2"
  assertEquals "$TEST_DIR/a [b]"     "$e3"
  assertEquals "$TEST_DIR/test file" "$e4"
  assertEquals "$TEST_DIR/test_file" "$e5"

  # Test ls with subdirectory
  ls_with_file_shortcuts 'a "b"' > $temp_file
  ls_output=$(<$temp_file strip_colors)
  assertIncludes "$ls_output" '[1]  c' F
  # Test that env variable is set correctly
  assertEquals "$TEST_DIR/a \"b\"/c" "$e1"
  # Test arg with no quotes
  ls_output=$(ls_with_file_shortcuts a\ \"b\" | strip_colors)
  assertIncludes "$ls_output" '[1]  c' F
}

# load and run shUnit2
source "$scmbDir/test/support/shunit2"
