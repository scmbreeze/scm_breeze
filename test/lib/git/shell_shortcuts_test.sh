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
  shell="zsh"
  SHUNIT_PARENT=$0
  setopt shwordsplit
else
  # Bash needs this option so that 'alias' works in a non-interactive shell
  shopt -s expand_aliases
fi

# Load test helpers
source "$scmbDir/test/support/test_helper"

# Setup
#-----------------------------------------------------------------------------
oneTimeSetUp() {
  export shell_command_wrapping_enabled="true"
  export scmb_wrapped_shell_commands="not_found cat rm cp mv ln ls cd sed"

  # Test functions
  function ls() { ls $@; }
  # Test aliases
  alias mv="nocorrect mv"
  alias rm="rm --option"
  alias sed="sed"
  # Test already wrapped commands
  alias ln="exec_scmb_expand_args /bin/ln"

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
  assertAliasEquals "exec_scmb_expand_args /bin/rm --option"  "rm"
  assertAliasEquals "exec_scmb_expand_args nocorrect /bin/mv" "mv"
  assertAliasEquals "exec_scmb_expand_args /bin/sed"          "sed"
  assertAliasEquals "exec_scmb_expand_args /bin/cat"          "cat"
  assertAliasEquals "exec_scmb_expand_args builtin cd"        "cd"
  assertAliasEquals "exec_scmb_expand_args __original_ls"     "ls"
  assertAliasEquals "exec_scmb_expand_args /bin/ln"           "ln"
}



# load and run shUnit2
source "$scmbDir/test/support/shunit2"
