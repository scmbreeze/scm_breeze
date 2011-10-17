#!/bin/bash
# ------------------------------------------------------------------------------
# SCM Breeze - Streamline your SCM workflow.
# Copyright 2011 Nathan Broadbent (http://madebynathan.com). All Rights Reserved.
# Released under the LGPL (GNU Lesser General Public License)
# ------------------------------------------------------------------------------
#
# Unit tests for git shell scripts

scmbDir="$( cd -P "$( dirname "$0" )" && pwd )"

# Zsh compatibility
if [ -n "${ZSH_VERSION:-}" ]; then shell="zsh"; SHUNIT_PARENT=$0; setopt shwordsplit; fi

# Load test helpers
. "$scmbDir/../../support/test_helper"

# Load functions to test
. "$scmbDir/../../../lib/_shared.sh"
. "$scmbDir/../../../lib/git/repo_management.sh"


# Setup and tear down
#-----------------------------------------------------------------------------
oneTimeSetUp() {
  GIT_REPO_DIR=$(mktemp -d)
  GIT_REPOS="/tmp/test_repo_1:/tmp/test_repo_11"
  git_status_command="git status"

  git_index_file="$GIT_REPO_DIR/.git_index"

  silentGitCommands

  cd $GIT_REPO_DIR
  # Setup test repos in temp repo dir
  for repo in github bitbucket source_forge; do
    mkdir $repo; cd $repo; git init; cd - > /dev/null
  done

  # Add some nested dirs for testing resursive tab completion
  mkdir -p github/videos/octocat/live_action
  # Add hidden dir to test that '.git' is filtered, but other hidden dirs are available.
  mkdir -p github/.im_hidden

  # Setup a test repo with some submodules
  # (just a dummy '.gitmodules' file and some nested .git directories)
  mkdir submodules_everywhere
  cd submodules_everywhere
  git init
  cat > .gitmodules <<EOF
[submodule "very/nested/directory/red_submodule"]
[submodule "very/nested/directory/green_submodule"]
[submodule "very/nested/directory/blue_submodule"]
EOF
  mkdir -p "very/nested/directory"
  cd "very/nested/directory"
  for repo in red_submodule green_submodule blue_submodule; do
    mkdir $repo; cd $repo; git init; cd - > /dev/null
  done

  # Setup some custom repos outside the main repo dir
  local IFS=":"
  for dir in $GIT_REPOS; do
    mkdir -p $dir; cd $dir; git init;
  done
  unset IFS

  verboseGitCommands

  cd "$orig_cwd"
}

oneTimeTearDown() {
  rm -rf "${GIT_REPO_DIR}"
  local IFS=":"
  for dir in $GIT_REPOS; do rm -rf $dir; done
}

ensureIndex() {
  _check_git_repo_index
}

index_no_newlines() {
  cat $git_index_file | tr "\\n" " "
}


#-----------------------------------------------------------------------------
# Unit tests
#-----------------------------------------------------------------------------

test_repo_index_command() {
  git_repo --rebuild-index > /dev/null

  # Test that all repos are detected, and sorted alphabetically
  assertIncludes "$(index_no_newlines)" "bitbucket.*\
blue_submodule.*\
github.*\
green_submodule.*\
red_submodule.*\
source_forge.*\
submodules_everywhere.*\
test_repo_11.*\
test_repo_1"

}

test_check_git_repo_index() {
  ensureIndex
  echo "should not be regenerated" >> $git_index_file
  _check_git_repo_index
  # Test that index is not rebuilt unless empty
  assertIncludes "$(index_no_newlines)" "should not be regenerated"
  rm $git_index_file
  # Test the index is rebuilt
  _check_git_repo_index
  assertTrue "[ -f $git_index_file ]"
}

test_git_repo_count() {
  assertEquals "9" "$(_git_repo_count)"
}

test_repo_list() {
  ensureIndex
  list=$(git_repo --list)
  assertIncludes "$list" "bitbucket"      || return
  assertIncludes "$list" "blue_submodule" || return
  assertIncludes "$list" "test_repo_11"
}

# Test matching rules for changing directory
test_git_repo_changing_directory() {
  ensureIndex
  git_repo "github";       assertEquals "$GIT_REPO_DIR/github" "$PWD"
  git_repo "github/";      assertEquals "$GIT_REPO_DIR/github" "$PWD"
  git_repo "bucket";       assertEquals "$GIT_REPO_DIR/bitbucket" "$PWD"
  git_repo "green_sub";    assertEquals "$GIT_REPO_DIR/submodules_everywhere/very/nested/directory/green_submodule" "$PWD"
  git_repo "_submod";      assertEquals "$GIT_REPO_DIR/submodules_everywhere/very/nested/directory/blue_submodule" "$PWD"
  git_repo "test_repo_1";  assertEquals "/tmp/test_repo_1" "$PWD"
  git_repo "test_repo_11"; assertEquals "/tmp/test_repo_11" "$PWD"
  git_repo "test_repo_";   assertEquals "/tmp/test_repo_11" "$PWD"
  git_repo "github/videos/octocat/live_action"; assertEquals "$GIT_REPO_DIR/github/videos/octocat/live_action" "$PWD"
}

test_git_repo_tab_completion() {
  # Only run tab completion test for bash
  if [[ "$0" == *bash ]]; then
    ensureIndex
    COMP_CWORD=0

    # Test that '--' commands have tab completion
    COMP_WORDS="--"
    _git_repo_tab_completion
    assertEquals "Incorrect number of tab-completed '--' commands" "5" "$(tab_completions | wc -w)"

    COMP_WORDS="gith"
    _git_repo_tab_completion
    assertIncludes "$(tab_completions)" "github/"

    # Test completion for project sub-directories when project ends with '/'
    COMP_WORDS="github/"
    _git_repo_tab_completion
    assertIncludes    "$(tab_completions)" "github/videos/"
    # Check that '.git/' is filtered from completion, but other hidden dirs are available
    assertNotIncludes "$(tab_completions)" "github/.git/"
    assertIncludes    "$(tab_completions)" "github/.im_hidden/"

    COMP_WORDS="github/videos/"
    _git_repo_tab_completion
    assertIncludes "$(tab_completions)" "github/videos/octocat/"


    # Test that completion checks for other matching projects even if one matches perfectly
    COMP_WORDS="test_repo_1"
    _git_repo_tab_completion
    assertIncludes "$(tab_completions)" "test_repo_1/ test_repo_11/"
  fi
}


# load and run shUnit2
# Call this function to run tests
. "$scmbDir/../../support/shunit2"

