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
  zsh_compat # Ensure shwordsplit is on for zsh
  git_clear_vars
  # Run ruby script, store output
  cmd_output=$(/usr/bin/env ruby "$scmbDir/lib/git/status_shortcuts.rb" $@)
  # Print debug information if $scmbDebug = "true"
  if [ "$scmbDebug" = "true" ]; then
    printf "status_shortcuts.rb output => \n$cmd_output\n------------------------\n"
  fi
  if [[ -z "$cmd_output" ]]; then
    # Just show regular git status if ruby script returns nothing.
    git status; return 1
  fi
  # Fetch list of files from last line of script output
  files="$(echo "$cmd_output" | grep '@@filelist@@::' | sed 's%@@filelist@@::%%g')"
  if [ "$scmbDebug" = "true" ]; then echo "filelist => $files"; fi
  # Export numbered env variables for each file
  IFS="|"
  local e=1
  for file in $files; do
    export $git_env_char$e="$file"
    if [ "$scmbDebug" = "true" ]; then echo "Set \$$git_env_char$e  => $file"; fi
    let e++
  done
  unset IFS

  if [ "$scmbDebug" = "true" ]; then echo "------------------------"; fi
  # Print status
  echo "$cmd_output" | grep -v '@@filelist@@::'
  zsh_reset # Reset zsh environment to default
}



# 'git add' & 'git rm' wrapper
# This shortcut means 'stage the change to the file'
# i.e. It will add new and changed files, and remove deleted files.
# Should be used in conjunction with the git_status_shortcuts() function for 'git status'.
# - 'auto git rm' behaviour can be turned off
# -------------------------------------------------------------------------------
git_add_shortcuts() {
  if [ -z "$1" ]; then
    echo "Usage: ga <file>  => git add <file>"
    echo "       ga 1       => git add \$e1"
    echo "       ga 2..4    => git add \$e2 \$e3 \$e4"
    echo "       ga 2 5..7  => git add \$e2 \$e5 \$e6 \$e7"
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
    function process {
      file=$1
      # Use 'git rm' if file doesn't exist and 'ga_auto_remove' is enabled.
      if [[ $ga_auto_remove == "yes" ]] && ! [ -e "$file" ]; then
        echo -n "# "
        git rm "$file"
      else
        git add "$file"
        echo -e "# add '$file'"
      fi
    }

    # Expand args and process resulting set of files.
    eval for file in $(git_expand_args "$@")\; do process "\$file"\; done
    echo "#"
  fi
}

# 'git add -p' wrapper
# This shortcut means 'stage my selection of patchs for the file'
# Should be used in conjunction with the git_status_shortcuts() function for 'git status'.
# -------------------------------------------------------------------------------
git_add_patch_shortcuts() {
  if [ -z "$1" ]; then
    echo "Usage: gap <file>  => git add -p <file>"
    echo "       gap 1       => git add -p \$e1"
    echo "       gap 2..4    => git add -p \$e2 \$e3 \$e4"
    echo "       gap 2 5..7  => git add -p \$e2 \$e5 \$e6 \$e7"
  else
    git_silent_add_patch_shortcuts "$@"
    # Makes sense to run 'git status' after this command.
    git_status_shortcuts
  fi
}
# Does nothing if no args are given.
git_silent_add_patch_shortcuts() {
  if [ -n "$1" ]; then
    # Expand args and process resulting set of files.
    IFS=$'\n'
    eval for file in $(git_expand_args "$@")\; do\
      git add -p "\$file"\;\
      echo -e "# add '\$file'"\;\
    done
    unset IFS
    echo "#"
  fi
}

# Prints a list of all files affected by a given SHA1,
# and exports numbered environment variables for each file.
git_show_affected_files(){
  f=0  # File count
  # Show colored revision and commit message
  echo -n "# "; git show --oneline --name-only $@ | head -n1; echo "# "
  for file in $(git show --pretty="format:" --name-only $@ | grep -v '^$'); do
    let f++
    export $git_env_char$f=$file     # Export numbered variable.
    echo -e "#     \e[2;37m[\e[0m$f\e[2;37m]\e[0m $file"
  done; echo "# "
}


# Allows expansion of numbered shortcuts, ranges of shortcuts, or standard paths.
# Numbered shortcut variables are produced by various commands, such as:
# * git_status_shortcuts()  - git status implementation
# * git_show_affected_files() - shows files affected by a given SHA1, etc.
git_expand_args() {
  first=1
  for arg in "$@"; do
    if [[ "$arg" =~ ^[0-9]+$ ]] ; then      # Substitute $e{*} variables for any integers
      if [ "$first" -eq 1 ]; then first=0; else echo -n " "; fi
      eval printf '%s' "\$$git_env_char$arg"
    elif [[ "$arg" =~ ^[0-9]+-[0-9]+$ ]]; then           # Expand ranges into $e{*} variables
      for i in $(eval echo {${arg/-/..}}); do
        if [ "$first" -eq 1 ]; then first=0; else echo -n " "; fi
        eval printf '%s' "\$$git_env_char$i"
      done
    else   # Otherwise, treat $arg as a normal string.
      if [ "$first" -eq 1 ]; then first=0; else echo -n " "; fi
      printf '%q' "$arg"
    fi
  done
}
# Execute a command with expanded args, e.g. Delete files 6 to 12: $ ge rm 6..12
# Fails if command is a number or range (probably not worth fixing)
exec_git_expand_args() { $(git_expand_args "$@"); }

# Clear numbered env variables
git_clear_vars() {
  for (( i=1; i<=$gs_max_changes; i++ )); do
    # Stop clearing after first empty var
    if [[ -z "$(eval echo "\$$git_env_char$i")" ]]; then break; fi
    unset $git_env_char$i
  done
}


# Shortcuts for resolving merge conflicts.
ours(){   local files=$(git_expand_args "$@"); git checkout --ours "$files"; git add "$files"; }
theirs(){ local files=$(git_expand_args "$@"); git checkout --theirs "$files"; git add "$files"; }


# Git commit prompts
# ------------------------------------------------------------------------------

# * Prompt for commit message
# * Execute prerequisite commands if message given, abort if not
# * Pipe commit message to 'git commit'
# * Add escaped commit command and unescaped message to bash history.
git_commit_prompt() {
  local commit_msg
  if [[ $shell == "zsh" ]]; then
    # zsh 'read' is weak. If you know how to make this better, please send a pull request.
    # (Bash 'read' supports prompt, arrow keys, home/end, up through bash history, etc.)
    echo -n "Commit Message: "; read commit_msg
  else
    read -r -e -p "Commit Message: " commit_msg
  fi

  if [ -n "$commit_msg" ]; then
    eval $@ # run any prequisite commands
    echo $commit_msg | git commit -F - | tail -n +2
  else
    echo -e "\e[0;31mAborting commit due to empty commit message.\e[0m"
  fi
  escaped=$(echo "$commit_msg" | sed -e 's/"/\\"/g' -e 's/!/"'"'"'!'"'"'"/g')

  if [[ $shell == "zsh" ]]; then
    print -s "git commit -m \"${escaped//\\/\\\\}\"" # zsh's print needs double escaping
    print -s "$commit_msg"
  else
    echo "git commit -m \"$escaped\"" >> $HISTFILE
    # Also add unescaped commit message, for git prompt
    echo "$commit_msg" >> $HISTFILE
  fi
}

# Prompt for commit message, then commit all modified and untracked files.
git_commit_all() {
  changes=$(git status --porcelain | wc -l)
  if [ "$changes" -gt 0 ]; then
    echo -e "\e[0;33mCommitting all files (\e[0;31m$changes\e[0;33m)\e[0m"
    git_commit_prompt "git add -A"
  else
    echo "# No changed files to commit."
  fi
}

# Add paths or expanded args if any given, then commit all staged changes.
git_add_and_commit() {
  git_silent_add_shortcuts "$@"
  changes=$(git diff --cached --numstat | wc -l)
  if [ "$changes" -gt 0 ]; then
    git_status_shortcuts 1  # only show staged changes
    git_commit_prompt
  else
    echo "# No staged changes to commit."
  fi
}

