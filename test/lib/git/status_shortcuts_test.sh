#!/bin/bash
# ------------------------------------------------------------------------------
# SCM Breeze - Streamline your SCM workflow.
# Copyright 2011 Nathan Broadbent (http://madebynathan.com). All Rights Reserved.
# Released under the LGPL (GNU Lesser General Public License)
# ------------------------------------------------------------------------------
#
# Unit tests for git shell scripts

export scmbDir="$( cd -P "$( dirname "$0" )" && pwd )/../../.."

# Zsh compatibility
if [ -n "${ZSH_VERSION:-}" ]; then shell="zsh"; SHUNIT_PARENT=$0; setopt shwordsplit; fi

# Load test helpers
source "$scmbDir/test/support/test_helper.sh"

# Load functions to test
source "$scmbDir/lib/scm_breeze.sh"
source "$scmbDir/lib/git/status_shortcuts.sh"


# Setup and tear down
#-----------------------------------------------------------------------------
oneTimeSetUp() {
  # Test Config
  export git_env_char="e"
  export gs_max_changes="20"
  export ga_auto_remove="yes"

  testRepo=$(mktemp -d -t scm_breeze.XXXXXXXXXX)
  testRepo=$(cd $testRepo && pwd -P)
}

oneTimeTearDown() {
  rm -rf "${testRepo}"
}

setupTestRepo() {
  rm -rf "${testRepo}"
  mkdir -p "$testRepo"
  cd "$testRepo"
  git init > /dev/null
}


#-----------------------------------------------------------------------------
# Unit tests
#-----------------------------------------------------------------------------

test_scmb_expand_args() {
  local e1="one" e2="two" e3="three" e4="four" e5="five" e6="six" e7='$dollar' e8='two words'
  local error="Args not expanded correctly"
  assertEquals "$error" "'one' 'three' 'six'" \
    "$(eval a=$(scmb_expand_args 1 3 6); token_quote "${a[@]}")"
  assertEquals "$error" "'one' 'two' 'three' 'five'" \
    "$(eval a=$(scmb_expand_args 1-3 5); token_quote "${a[@]}")"
  assertEquals "$error" "'\$dollar' 'two' 'three' 'four' 'one'" \
    "$(eval a=$(scmb_expand_args 7 2-4 1); token_quote "${a[@]}")"

  # Test that any args with spaces remain quoted
  assertEquals "$error" "'-m' 'Test Commit Message' 'one'" \
    "$(eval a=$(scmb_expand_args -m "Test Commit Message" 1); token_quote "${a[@]}")"
  assertEquals "$error" "'-ma' 'Test Commit Message' 'Unquoted'"\
    "$(eval a=$(scmb_expand_args -ma "Test Commit Message" "Unquoted"); token_quote "${a[@]}")"
  assertEquals "$error" "'\$dollar' 'one' 'two words'" \
    "$(eval a=$(scmb_expand_args 7 1-1 8); token_quote "${a[@]}")"
}

test_command_wrapping_escapes_special_characters() {
    assertEquals 'should escape | the pipe' "$(exec_scmb_expand_args echo "should escape | the pipe")"
    assertEquals 'should escape ; the semicolon' "$(exec_scmb_expand_args echo "should escape ; the semicolon")"
}

test_git_status_shortcuts() {
  setupTestRepo

  silentGitCommands

  # Set up some modifications
  touch deleted_file
  git add deleted_file
  git commit -m "Test commit"
  touch new_file
  touch untracked_file
  git add new_file
  echo "changed" > new_file
  rm deleted_file

  verboseGitCommands

  # Test that groups can be filtered by passing a parameter
  git_status1=$(git_status_shortcuts 1)
  git_status3=$(git_status_shortcuts 3)
  git_status4=$(git_status_shortcuts 4)

  # Test for presence of expected groups
  assertIncludes "$git_status1" "Changes to be committed"
  assertIncludes "$git_status3" "Changes not staged for commit"
  assertIncludes "$git_status4" "Untracked files"
  assertNotIncludes "$git_status3" "Changes to be committed"
  assertNotIncludes "$git_status4" "Changes not staged for commit"
  assertNotIncludes "$git_status1" "Untracked files"
  assertNotIncludes "$git_status4" "Changes to be committed"
  assertNotIncludes "$git_status1" "Changes not staged for commit"
  assertNotIncludes "$git_status3" "Untracked files"

  # Run command in shell, load output from temp file into variable
  # (This is needed so that env variables are exported in the current shell)
  temp_file=$(mktemp -t scm_breeze.XXXXXXXXXX)
  git_status_shortcuts > $temp_file
  git_status=$(<$temp_file strip_colors)

  assertIncludes "$git_status"  "new file: *\[1\] *new_file"       || return
  assertIncludes "$git_status"   "deleted: *\[2\] *deleted_file"   || return
  assertIncludes "$git_status"  "modified: *\[3\] *new_file"       || return
  assertIncludes "$git_status" "untracked: *\[4\] *untracked_file" || return

  # Test that shortcut env variables are set with full path
  local error="Env variable was not set"
  assertEquals "$error" "$testRepo/new_file" "$e1"       || return
  assertEquals "$error" "$testRepo/deleted_file" "$e2"   || return
  assertEquals "$error" "$testRepo/new_file" "$e3"       || return
  assertEquals "$error" "$testRepo/untracked_file" "$e4" || return
}

test_git_status_produces_relative_paths() {
  setupTestRepo

  mkdir -p dir1/sub1/subsub1
  mkdir -p dir1/sub2
  mkdir -p dir2
  touch dir1/sub1/subsub1/testfile
  touch dir1/sub2/testfile
  touch dir2/testfile
  git add .

  git_status=$(git_status_shortcuts | strip_colors)
  assertIncludes "$git_status"  "dir1/sub1/subsub1/testfile" || return

  cd $testRepo/dir1
  git_status=$(git_status_shortcuts | strip_colors)
  assertIncludes "$git_status"  " sub1/subsub1/testfile" || return
  assertIncludes "$git_status"  " sub2/testfile" || return
  assertIncludes "$git_status"  "../dir2/testfile" || return

  cd $testRepo/dir1/sub1
  git_status=$(git_status_shortcuts | strip_colors)
  assertIncludes "$git_status"  " subsub1/testfile"   || return
  assertIncludes "$git_status"  " ../sub2/testfile"   || return
  assertIncludes "$git_status"  "../../dir2/testfile" || return

  cd $testRepo/dir1/sub1/subsub1
  git_status=$(git_status_shortcuts | strip_colors)
  assertIncludes "$git_status"  " testfile" || return
  assertIncludes "$git_status"  " ../../sub2/testfile"   || return
  assertIncludes "$git_status"  "../../../dir2/testfile" || return
}


test_git_status_shortcuts_merge_conflicts() {
  setupTestRepo

  silentGitCommands

  # Set up every possible merge conflict
  touch both_modified both_deleted deleted_by_them deleted_by_us
  echo "renamed file needs some content" > renamed_file
  git add both_modified both_deleted renamed_file deleted_by_them deleted_by_us
  git commit -m "First commit"

  git checkout -b conflict_branch
  echo "added by branch" > both_added
  echo "branch line" > both_modified
  echo "deleted by us" > deleted_by_us
  git rm deleted_by_them both_deleted
  git mv renamed_file renamed_file_on_branch
  git add both_added both_modified deleted_by_us
  git commit -m "Branch commit"

  git checkout master
  echo "added by master" > both_added
  echo "master line" > both_modified
  echo "deleted by them" > deleted_by_them
  git rm deleted_by_us both_deleted
  git mv renamed_file renamed_file_on_master
  git add both_added both_modified deleted_by_them
  git commit -m "Master commit"

  git merge conflict_branch

  verboseGitCommands

  # Test output without stripped color codes
  git_status=$(git_status_shortcuts | strip_colors)
  assertIncludes "$git_status"      "both added: *\[[0-9]*\] *both_added"             || return
  assertIncludes "$git_status"   "both modified: *\[[0-9]*\] *both_modified"          || return
  assertIncludes "$git_status" "deleted by them: *\[[0-9]*\] *deleted_by_them"        || return
  assertIncludes "$git_status"   "deleted by us: *\[[0-9]*\] *deleted_by_us"          || return
  assertIncludes "$git_status"    "both deleted: *\[[0-9]*\] *renamed_file"           || return
  assertIncludes "$git_status"   "added by them: *\[[0-9]*\] *renamed_file_on_branch" || return
  assertIncludes "$git_status"     "added by us: *\[[0-9]*\] *renamed_file_on_master" || return
}


test_git_status_shortcuts_max_changes() {
  setupTestRepo

  export gs_max_changes="5"

  # Add 5 untracked files
  touch a b c d e
  git_status=$(git_status_shortcuts | strip_colors)
  for i in {1..5}; do
    assertIncludes "$git_status"  "\[$i\]" || return
  done

  # 6 untracked files is more than $gs_max_changes
  touch f
  git_status=$(git_status_shortcuts | strip_colors)
  assertNotIncludes "$git_status"  "\[[0-9]*\]" || return
  assertIncludes "$git_status"  "There were more than 5 changed files." || return

  export gs_max_changes="20"
}


test_git_add_shortcuts() {
  setupTestRepo

  touch a b c d e f g h i j
  # Show git status, which sets up env variables
  git_status_shortcuts > /dev/null
  git_add_shortcuts 2-4 7 8 > /dev/null
  git_status=$(git_status_shortcuts 1 | strip_colors)

  for c in b c d g h; do
    assertIncludes "$git_status"  "\[[0-9]*\] $c" || return
  done
}

test_git_commit_prompt() {
  setupTestRepo

  commit_msg="\"Nathan's git commit prompt function!\""
  dbl_escaped_msg="\\\\\"Nathan's git commit prompt function\"'"'!'"'\"\\\\\""
  # Create temporary history file
  export HISTFILE=$(mktemp -t scm_breeze.XXXXXXXXXX)
  export HISTFILESIZE=1000
  export HISTSIZE=1000

  touch a b c d
  git add . > /dev/null

  # Zsh 'vared' doesn't handle input via pipe, so replace with function that reads into commit_msg variable.
  function vared(){ read commit_msg; }

  # Test the git commit prompt, by piping a commit message
  # instead of user input.
  echo "$commit_msg" | git_commit_prompt > /dev/null

  git_show_output=$(git show --oneline --name-only)
  assertIncludes "$git_show_output"  "$commit_msg"

  # Test that history was appended correctly.
  if [[ $shell == "zsh" ]]; then
    test_history="$(history)"
  else
    test_history="$(cat $HISTFILE)"
  fi
  assertIncludes "$test_history"  "$commit_msg"
  assertIncludes "$test_history"  "git commit -m \"$dbl_escaped_msg\""
}

test_git_commit_prompt_with_append() {
  setupTestRepo

  commit_msg="Updating README, no build please"

  # Create temporary history file
  HISTFILE=$(mktemp -t scm_breeze.XXXXXXXXXX)
  HISTFILESIZE=1000
  HISTSIZE=1000

  touch a b c
  git add . > /dev/null

  # Zsh 'vared' doesn't handle input via pipe, so replace with function that reads into commit_msg variable.
  function vared(){ read commit_msg; }

  # Test the git commit prompt, by piping a commit message
  # instead of user input.
  echo "$commit_msg" | APPEND="[ci skip]" git_commit_prompt > /dev/null

  git_show_output=$(git show --oneline --name-only)
  assertIncludes "$git_show_output"  "$commit_msg \[ci skip\]"

  # Test that history was appended correctly.
  if [[ $shell == "zsh" ]]; then
    test_history="$(history)"
  else
    test_history="$(cat $HISTFILE)"
  fi
  assertIncludes "$test_history"  "$commit_msg \[ci skip\]"
  assertIncludes "$test_history"  "git commit -m \"$commit_msg \[ci skip\]\""
}

test_adding_files_with_spaces() {
  setupTestRepo

  test_file="file with spaces.txt"

  touch "$test_file"
  e1="$testRepo/$test_file"
  git_add_shortcuts 1 > /dev/null

  # Test that file is added by looking at git status
  git_status=$(git_status_shortcuts | strip_colors)
  assertIncludes "$git_status"  "new file: \[1\] \"$test_file"
}



# load and run shUnit2
source "$scmbDir/test/support/shunit2"
