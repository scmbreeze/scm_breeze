#!/bin/bash
# ------------------------------------------------------------------------------
# SCM Breeze - Streamline your SCM workflow.
# Copyright 2011 Nathan Broadbent (http://madebynathan.com). All Rights Reserved.
# Released under the LGPL (GNU Lesser General Public License)
# ------------------------------------------------------------------------------
#
# Unit tests for git/compatibility.sh

export scmbDir="$(cd -P "$(dirname "$0")" && pwd)/../../.."

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
source "$scmbDir/test/support/test_helper.sh"

# Setup
#-----------------------------------------------------------------------------
oneTimeSetUp() {
  # Save any existing variables to restore later
  for var in GIT_ENV_CHAR GS_MAX_CHANGES GA_AUTO_REMOVE GIT_SETUP_ALIASES GIT_SKIP_SHELL_COMPLETION GIT_REPO_DIR GIT_STATUS_COMMAND; do
    eval "orig_${var}=\${${var}:-}"
    eval "unset ${var}"
    # Also unset lowercase version
    lower=$(echo "$var" | tr '[:upper:]' '[:lower:]')
    eval "orig_${lower}=\${${lower}:-}"
    eval "unset ${lower}"
  done
}

oneTimeTearDown() {
  # Restore original variables
  for var in GIT_ENV_CHAR GS_MAX_CHANGES GA_AUTO_REMOVE GIT_SETUP_ALIASES GIT_SKIP_SHELL_COMPLETION GIT_REPO_DIR GIT_STATUS_COMMAND; do
    eval "orig_val=\${orig_${var}:-}"
    if [ -n "$orig_val" ]; then
      eval "export ${var}=\"\$orig_val\""
    else
      eval "unset ${var}"
    fi
    # Also restore lowercase version
    lower=$(echo "$var" | tr '[:upper:]' '[:lower:]')
    eval "orig_val=\${orig_${lower}:-}"
    if [ -n "$orig_val" ]; then
      eval "export ${lower}=\"\$orig_val\""
    else
      eval "unset ${lower}"
    fi
  done
}

setUp() {
  # Unset all variables before each test
  for var in GIT_ENV_CHAR GS_MAX_CHANGES GA_AUTO_REMOVE GIT_SETUP_ALIASES GIT_SKIP_SHELL_COMPLETION GIT_REPO_DIR GIT_STATUS_COMMAND; do
    eval "unset ${var}"
    # Also unset lowercase version
    lower=$(echo "$var" | tr '[:upper:]' '[:lower:]')
    eval "unset ${lower}"
  done
}

# Tests
#-----------------------------------------------------------------------------

test_uppercase_variables_not_overwritten() {
  # Set uppercase variables
  export GIT_ENV_CHAR="@"
  export GS_MAX_CHANGES="150"

  # Source compatibility script
  source "$scmbDir/lib/git/compatibility.sh"

  # Check that uppercase variables are not changed
  assertEquals "@" "$GIT_ENV_CHAR"
  assertEquals "150" "$GS_MAX_CHANGES"
}

test_lowercase_variables_converted_to_uppercase() {
  # Set lowercase variables
  export git_env_char="#"
  export gs_max_changes="200"

  # Source compatibility script
  source "$scmbDir/lib/git/compatibility.sh"

  # Check that uppercase variables are set from lowercase
  assertEquals "#" "$GIT_ENV_CHAR"
  assertEquals "200" "$GS_MAX_CHANGES"
}

test_uppercase_variables_take_precedence() {
  # Set both uppercase and lowercase variables
  export GIT_ENV_CHAR="@"
  export git_env_char="#"
  export GS_MAX_CHANGES="150"
  export gs_max_changes="200"

  # Source compatibility script
  source "$scmbDir/lib/git/compatibility.sh"

  # Check that uppercase variables take precedence
  assertEquals "@" "$GIT_ENV_CHAR"
  assertEquals "150" "$GS_MAX_CHANGES"
}

test_all_variables_converted() {
  # Set all lowercase variables
  export git_env_char="#"
  export gs_max_changes="200"
  export ga_auto_remove="true"
  export git_setup_aliases="false"
  export git_skip_shell_completion="true"
  export git_repo_dir="/test/path"
  export git_status_command="git status -sb"

  # Source compatibility script
  source "$scmbDir/lib/git/compatibility.sh"

  # Check that all uppercase variables are set from lowercase
  assertEquals "#" "$GIT_ENV_CHAR"
  assertEquals "200" "$GS_MAX_CHANGES"
  assertEquals "true" "$GA_AUTO_REMOVE"
  assertEquals "false" "$GIT_SETUP_ALIASES"
  assertEquals "true" "$GIT_SKIP_SHELL_COMPLETION"
  assertEquals "/test/path" "$GIT_REPO_DIR"
  assertEquals "git status -sb" "$GIT_STATUS_COMMAND"
}

# Load and run shUnit2
source "$scmbDir/test/support/shunit2"
