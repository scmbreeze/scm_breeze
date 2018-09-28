# ------------------------------------------------------------------------------
# SCM Breeze - Streamline your SCM workflow.
# Copyright 2011 Nathan Broadbent (http://madebynathan.com). All Rights Reserved.
# Released under the LGPL (GNU Lesser General Public License)
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Numbered file shortcuts for git commands
# ------------------------------------------------------------------------------


# Processes 'git status --porcelain', and exports numbered
# env variables that contain the path of each affected file.
# Output is also more concise than standard 'git status'.
#
# Call with optional <group> parameter to filter by modification state:
# 1 || staged,  2 || unmerged,  3 || unstaged,  4 || untracked
# --------------------------------------------------------------------
git_status_shortcuts() {
  fail_if_not_git_repo || return 1
  zsh_compat # Ensure shwordsplit is on for zsh
  git_clear_vars
  # Run ruby script, store output
  local cmd_output="$(/usr/bin/env ruby "$scmbDir/lib/git/status_shortcuts.rb" "$@")"
  # Print debug information if $scmbDebug = "true"
  if [ "${scmbDebug:-}" = "true" ]; then
    printf "status_shortcuts.rb output => \n$cmd_output\n------------------------\n"
  fi
  if [[ -z "$cmd_output" ]]; then
    # Just show regular git status if ruby script returns nothing.
    git status
    echo -e "\n\033[33mThere were more than $gs_max_changes changed files. SCM Breeze has fallen back to standard \`git status\` for performance reasons.\033[0m"
    return 1
  fi
  # Fetch list of files from last line of script output
  files="$(echo "$cmd_output" | \grep '@@filelist@@::' | sed 's%@@filelist@@::%%g')"
  if [ "${scmbDebug:-}" = "true" ]; then echo "filelist => $files"; fi
  # Export numbered env variables for each file
  local IFS="|"
  local e=1
  for file in $files; do
    export $git_env_char$e="$file"
    if [ "${scmbDebug:-}" = "true" ]; then echo "Set \$$git_env_char$e  => $file"; fi
    let e++
  done

  if [ "${scmbDebug:-}" = "true" ]; then echo "------------------------"; fi
  # Print status
  echo "$cmd_output" | \grep -v '@@filelist@@::'
  zsh_reset # Reset zsh environment to default
}



# 'git add' & 'git rm' wrapper
# This shortcut means 'stage the change to the file'
# i.e. It will add new and changed files, and remove deleted files.
# Should be used in conjunction with the git_status_shortcuts() function for 'git status'.
# - 'auto git rm' behaviour can be turned off
# -------------------------------------------------------------------------------
git_add_shortcuts() {
  fail_if_not_git_repo || return 1
  if [ -z "$1" ]; then
    echo "Usage: ga <file>  => git add <file>"
    echo "       ga 1       => git add \$e1"
    echo "       ga 2-4    => git add \$e2 \$e3 \$e4"
    echo "       ga 2 5-7  => git add \$e2 \$e5 \$e6 \$e7"
    if [[ $ga_auto_remove == "yes" ]]; then
      echo -e "\nNote: Deleted files will also be staged using this shortcut."
      echo "      To turn off this behaviour, change the 'auto_remove' option."
    fi
  else
    git_silent_add_shortcuts "$@"
    # Makes sense to run 'git status' after this command.
    git_status_shortcuts
  fi
}
# Does nothing if no args are given.
git_silent_add_shortcuts() {
  if [ -n "$1" ]; then
    # Expand args and process resulting set of files.
    local args
    eval args="$(scmb_expand_args "$@")"  # populate $args array
    for file in "${args[@]}"; do
      # Use 'git rm' if file doesn't exist and 'ga_auto_remove' is enabled.
      if [[ $ga_auto_remove = yes && ! -e $file ]]; then
        echo -n "# "
        git rm "$file"
      else
        git add "$file"
        echo -e "# Added '$file'"
      fi
    done
    echo "#"
  fi
}

# Prints a list of all files affected by a given SHA1,
# and exports numbered environment variables for each file.
git_show_affected_files(){
  fail_if_not_git_repo || return 1
  local f=0  # File count
  # Show colored revision and commit message
  echo -n "# "; git show --oneline --name-only "$@" | head -n1; echo "# "
  for file in $(git show --pretty="format:" --name-only "$@" | \grep -v '^$'); do
    let f++
    export $git_env_char$f=$file     # Export numbered variable.
    echo -e "#     \033[2;37m[\033[0m$f\033[2;37m]\033[0m $file"
  done; echo "# "
}

# Allows expansion of numbered shortcuts, ranges of shortcuts, or standard paths.
# Return a string which can be `eval`ed like: eval args="$(scmb_expand_args "$@")"
# Numbered shortcut variables are produced by various commands, such as:
# * git_status_shortcuts()  - git status implementation
# * git_show_affected_files() - shows files affected by a given SHA1, etc.
scmb_expand_args() {
  # Check for --relative param
  if [ "$1" = "--relative" ]; then
    local relative=1
    shift
  fi

  local args
  args=()  # initially empty array. zsh 5.0.2 from Ubuntu 14.04 requires this to be separated
  for arg in "$@"; do
    if [[ "$arg" =~ ^[0-9]{0,4}$ ]] ; then      # Substitute $e{*} variables for any integers
      if [ -e "$arg" ]; then
        # Don't expand files or directories with numeric names
        args+=("$arg")
      else
        args+=("$(_print_path "$relative" "$git_env_char$arg")")
      fi
    elif [[ "$arg" =~ ^[0-9]+-[0-9]+$ ]]; then           # Expand ranges into $e{*} variables
      for i in $(eval echo {${arg/-/..}}); do
        args+=("$(_print_path "$relative" "$git_env_char$i")")
      done
    else   # Otherwise, treat $arg as a normal string.
      args+=("$arg")
    fi
  done

  # "declare -p" with zsh 5.0.2 on Ubuntu 14.04 creates a string that it cannot process:
  # typeset -a args args=(one three six)
  # There should be a ; between the two "args" tokens
  # "declare -p" with bash 4.3.11(1) on Ubuntu 14.04 creates a string like:
  # declare -a a='([0]="a" [1]="b c" [2]="d")'
  # The RHS of this string is incompatible with zsh 5.0.2 and "eval args="

  # Generate a quoted array string to assign to "eval args="
  echo "( $(token_quote "${args[@]}") )"
}

# Expand a variable (named by $2) into a (possibly relative) pathname
_print_path() {
  local pathname
  pathname=$(eval printf '%s' "\"\${$2}\"")
  if [ "$1" = 1 ]; then  # print relative
    pathname=${pathname#$PWD/}  # Remove $PWD from beginning of the path
  fi
  printf '%s' "$pathname"
}

# Execute a command with expanded args, e.g. Delete files 6 to 12: $ ge rm 6-12
# Fails if command is a number or range (probably not worth fixing)
exec_scmb_expand_args() {
  local args
  eval "args=$(scmb_expand_args "$@")"  # populate $args array
  _safe_eval "${args[@]}"
}

# Clear numbered env variables
git_clear_vars() {
  local i
  for (( i=1; i<=$gs_max_changes; i++ )); do
    # Stop clearing after first empty var
    local env_var_i=${git_env_char}${i}
    if [[ -z "$(eval echo "\${$env_var_i:-}")" ]]; then
      break
    else
      unset $env_var_i
    fi
  done
}


# Shortcuts for resolving merge conflicts.
_git_resolve_merge_conflict() {
  if [ -n "$2" ]; then
    # Expand args and process resulting set of files.
    local args
    eval "args=$(scmb_expand_args "$@")"  # populate $args array
    for file in "${args[@]:2}"; do
      git checkout "--$1""s" "$file"   # "--$1""s" is expanded to --ours or --theirs
      git add "$file"
      echo -e "# Added $1 version of '$file'"
    done
    echo -e "# -- If you have finished resolving conflicts, commit the resolutions with 'git commit'"
  fi
}
ours(){   _git_resolve_merge_conflict "our" "$@"; }
theirs(){ _git_resolve_merge_conflict "their" "$@"; }


# Git commit prompts
# ------------------------------------------------------------------------------

# * Prompt for commit message
# * Execute prerequisite commands if message given, abort if not
# * Pipe commit message to 'git commit'
# * Add escaped commit command and unescaped message to bash history.
git_commit_prompt() {
  local commit_msg
  local saved_commit_msg
  if [ -f "/tmp/.git_commit_message~" ]; then
    saved_commit_msg="$(cat /tmp/.git_commit_message~)"
    echo -e "\033[0;36mLeave blank to use saved commit message: \033[0m$saved_commit_msg"
  fi
  if [[ $shell == "zsh" ]]; then
    vared -h -p "Commit Message: " commit_msg
  else
    read -r -e -p "Commit Message: " commit_msg
  fi

  if [ -z "$commit_msg" ]; then
    if [ -n "$saved_commit_msg" ]; then
      commit_msg="$saved_commit_msg"
    else
      echo -e "\033[0;31mAborting commit due to empty commit message.\033[0m"
      return
    fi
  fi

  # Add $GIT_COMMIT_MSG_SUFFIX to commit message, if given.
  # (Used to append things like [ci skip] for Travis CI)
  if [ -n "$GIT_COMMIT_MSG_SUFFIX" ]; then
    commit_msg="$commit_msg $GIT_COMMIT_MSG_SUFFIX"
  fi

  # Exclamation marks are really difficult to escape properly in a bash prompt.
  # They must always be enclosed with single quotes.
  escaped_msg=$(echo "$commit_msg" | sed -e 's/"/\\"/g' -e "s/!/\"'!'\"/g")
  # Add command to bash history, so that if a git pre-commit hook fails,
  # you can just press "up" and "return" to retry the commit.
  if [[ $shell == "zsh" ]]; then
    # zsh's print needs double escaping
    print -s "git commit -m \"${escaped_msg//\\/\\\\}\""
  else
    history -s "git commit -m \"$escaped_msg\""
    # Need to write history to a file for tests
    if [ -n "$SHUNIT_VERSION" ]; then history -w $HISTFILE; fi
  fi

  # Also save the commit message to a temp file in case git commit fails
  echo "$commit_msg" > "/tmp/.git_commit_message~"
  eval $@ # run any prequisite commands

  echo "$commit_msg" | git commit -F - | tail -n +2

  # Fetch the pipe status (for both bash and zsh):
  GIT_PIPE_STATUS=("${PIPESTATUS[@]}${pipestatus[@]}")
  if [[ $shell == "zsh" ]]; then
    git_exit_status="${GIT_PIPE_STATUS[2]}" # zsh array indexes start at 1
  else
    git_exit_status="${GIT_PIPE_STATUS[1]}"
  fi
  if [[ "$git_exit_status" == 0 ]]; then
    # Delete saved commit message if commit was successful
    rm -f "/tmp/.git_commit_message~"
  fi
}

# Prompt for commit message, then commit all modified and untracked files.
git_commit_all() {
  fail_if_not_git_repo || return 1
  changes=$(git status --porcelain | wc -l | tr -d ' ')
  if [ "$changes" -gt 0 ]; then
    if [ -n "$GIT_COMMIT_MSG_SUFFIX" ]; then
      local appending=" | \033[0;36mappending '\033[1;36m$GIT_COMMIT_MSG_SUFFIX\033[0;36m' to commit message.\033[0m"
    fi
    echo -e "\033[0;33mCommitting all files (\033[0;31m$changes\033[0;33m)\033[0m$appending"
    git_commit_prompt "git add --all ."
  else
    echo "# No changed files to commit."
  fi
}

# Add paths or expanded args if any given, then commit all staged changes.
git_add_and_commit() {
  fail_if_not_git_repo || return 1
  git_silent_add_shortcuts "$@"
  changes=$(git diff --cached --numstat | wc -l)
  if [ "$changes" -gt 0 ]; then
    git_status_shortcuts 1  # only show staged changes
    git_commit_prompt
  else
    echo "# No staged changes to commit."
  fi
}
