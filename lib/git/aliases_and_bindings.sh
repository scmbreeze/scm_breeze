#
# Set up configured aliases & keyboard shortcuts
# --------------------------------------------------------------------
# _alias() ignores errors if alias is not defined. (from lib/scm_breeze.sh)

# Print formatted alias index
list_aliases() { alias | grep "$*" --color=never | sed -e 's/alias //' -e "s/=/::/" -e "s/'//g" | awk -F "::" '{ printf "\033[1;36m%15s  \033[2;37m=>\033[0m  %-8s\n",$1,$2}'; }
alias git_aliases="list_aliases git"

# Remove any existing git alias or function
unalias git > /dev/null 2>&1
unset -f git > /dev/null 2>&1

# Use the full path to git to avoid infinite loop with git function
export _git_cmd="$(\which git)"
# Wrap git with the 'hub' github wrapper, if installed (https://github.com/defunkt/hub)
if type hub > /dev/null 2>&1; then export _git_cmd="hub"; fi


# Create 'git' function that calls hub if defined, and expands all numeric arguments
function git(){
  # Only expand args for a subset of git commands
  case $1 in
    checkout|commit|reset|rm|blame|diff|add|log)
      exec_scmb_expand_args "$_git_cmd" "$@";;
    *)
      "$_git_cmd" "$@";;
  esac
}

_alias $git_alias='git'


# --------------------------------------------------------------------
# Thanks to Scott Bronson for coming up the following git tab completion workaround,
# which I've altered slightly to be more flexible.
# https://github.com/bronson/dotfiles/blob/731bfd951be68f395247982ba1fb745fbed2455c/.bashrc#L81
# (only works for bash)
__define_git_completion () {
eval "
_git_$1_shortcut () {
COMP_LINE=\"git $2 \${COMP_LINE/$1 }\"
let COMP_POINT+=$((4+${#2}-${#1}))
COMP_WORDS=(git $2 \"\${COMP_WORDS[@]:1}\")
let COMP_CWORD+=1

local cur words cword prev
_get_comp_words_by_ref -n =: cur words cword prev
_git
}
"
}

# Define git alias with tab completion
# Usage: __git_alias <alias> <command_prefix> <command>
__git_alias () {
  if [ -n "$1" ]; then
    local alias_str="$1"; local cmd_prefix="$2"; local cmd="$3"; local cmd_args="${4-}"
    alias $alias_str="$cmd_prefix $cmd${cmd_args:+ }$cmd_args"
    if [ "$shell" = "bash" ]; then
      __define_git_completion $alias_str $cmd
      complete -o default -o nospace -F _git_"$alias_str"_shortcut $alias_str
    fi
  fi
}

# --------------------------------------------------------------------
# SCM Breeze functions
_alias $git_status_shortcuts_alias="git_status_shortcuts"
_alias $git_add_shortcuts_alias="git_add_shortcuts"
_alias $exec_scmb_expand_args_alias="exec_scmb_expand_args"
_alias $git_show_files_alias="git_show_affected_files"
_alias $git_commit_all_alias='git_commit_all'

# Git Index alias
_alias $git_index_alias="git_index"

# Only set up the following aliases if 'git_setup_aliases' is 'yes'
if [ "$git_setup_aliases" = "yes" ]; then

  # Commands that deal with paths
  __git_alias "$git_checkout_alias"    "git" "checkout"
  __git_alias "$git_commit_alias"      "git" "commit"
  __git_alias "$git_reset_alias"       "git" "reset"
  __git_alias "$git_reset_del_alias"   "git" "reset" "--"
  __git_alias "$git_reset_hard_alias"  "git" "reset" "--hard"
  __git_alias "$git_rm_alias"          "git" "rm"
  __git_alias "$git_blame_alias"       "git" "blame"
  __git_alias "$git_diff_alias"        "git" "diff"
  __git_alias "$git_diff_cached_alias" "git" "diff" "--cached"
  __git_alias "$git_add_patch_alias"   "git" "add" "-p"
  # Custom default format for git log
  git_log_command="log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
  __git_alias "$git_log_alias" "git" "$git_log_command"

  # Standard commands
  __git_alias "$git_clone_alias" "git" 'clone'
  __git_alias "$git_fetch_alias" "git" 'fetch'
  __git_alias "$git_checkout_branch_alias" "git" 'checkout' "-b"
  __git_alias "$git_pull_alias" "git" 'pull'
  __git_alias "$git_push_alias" "git" 'push'
  __git_alias "$git_status_original_alias" "git" 'status' # (Standard git status)
  __git_alias "$git_status_short_alias" "git" 'status' '-s'
  __git_alias "$git_clean_alias" "git" "clean"
  __git_alias "$git_clean_force_alias" "git" "clean" "-fd"
  __git_alias "$git_remote_alias" "git" 'remote' '-v'
  __git_alias "$git_branch_alias" "git" 'branch'
  __git_alias "$git_rebase_alias" "git" 'rebase'
  __git_alias "$git_rebase_alias_continue" "git" 'rebase' "--continue"
  __git_alias "$git_rebase_alias_abort" "git" 'rebase' "--abort"
  __git_alias "$git_merge_alias" "git" 'merge'
  __git_alias "$git_cherry_pick_alias" "git" 'cherry-pick'
  __git_alias "$git_show_alias" "git" 'show'


  # Compound/complex commands
  _alias $git_fetch_all_alias="git fetch --all"
  _alias $git_pull_then_push_alias="git pull && git push"
  _alias $git_fetch_and_rebase_alias='git fetch && git rebase'
  _alias $git_commit_amend_alias='git commit --amend'
  # Add staged changes to latest commit without prompting for message
  _alias $git_commit_amend_no_msg_alias='git commit --amend -C HEAD'
  _alias $git_commit_no_msg_alias='git commit -C HEAD'
  _alias $git_log_stat_alias='git log --stat --max-count=5'
  _alias $git_log_graph_alias='git log --graph --max-count=5'
  _alias $git_add_all_alias='git add -A'
  _alias $git_branch_all_alias='git branch -a'
fi



# Tab completion
if [ $shell = "bash" ]; then
  complete -o default -o nospace -F _git $git_alias

  # Git repo management & aliases.
  # If you know how to rewrite _git_index_tab_completion() for zsh, please send me a pull request!
  complete -o nospace -o filenames -F _git_index_tab_completion git_index
  complete -o nospace -o filenames -F _git_index_tab_completion $git_index_alias
fi


# Keyboard Bindings
# -----------------------------------------------------------
# 'git_commit_all' and 'git_add_and_commit' give commit message prompts.
# See [here](http://qntm.org/bash#sec1) for info about why I wanted a prompt.

# Cross-shell key bindings
_bind(){
  if [ -n "$1" ]; then
    if [[ $shell == "zsh" ]]; then
      bindkey -s "$1" "$2"
    else # bash
      bind "\"$1\": $2"
    fi
  fi
}

# Keyboard shortcuts for commits
if [[ "$git_keyboard_shortcuts_enabled" = "true" ]]; then
  case "$-" in
  *i*)
      # Uses emacs style keybindings, so vi mode is not supported for now
      if ! set -o | grep -q '^vi .*on$'; then
        if [[ $shell == "zsh" ]]; then
          _bind "$git_commit_all_keys" " git_commit_all""\n"
          _bind "$git_add_and_commit_keys" " \e[1~ git_add_and_commit""\n"
        else
          _bind "$git_commit_all_keys" "\" git_commit_all\n\""
          _bind "$git_add_and_commit_keys" "\"\e[1~ git_add_and_commit \n\""
        fi
      fi

      # Commands are prepended with a space so that they won't be added to history.
      # Make sure this is turned on with:
      # zsh:  setopt histignorespace histignoredups
      # bash: HISTCONTROL=ignorespace:ignoredups
  esac
fi

# Wrap common commands with numeric argument expansion.
# Prepends everything with exec_scmb_expand_args,
# even if commands are already aliases or functions
if [ "$shell_command_wrapping_enabled" = "true" ] || [ "$bash_command_wrapping_enabled" = "true" ]; then
  # Do it in a function so we don't bleed variables
  function _git_wrap_commands() {
    # Define 'whence' for bash, to get the value of an alias
    type whence > /dev/null 2>&1 || function whence() { type "$@" | sed -e "s/.*is aliased to \`//" -e "s/'$//"; }
    local cmd=''
    for cmd in vim emacs gedit cat rm cp mv ln ls cd; do
      case "$(type $cmd 2>&1)" in
      *'exec_scmb_expand_args'*|*'not found'*);; # Don't do anything if command not found, or already aliased.

      *'is aliased to'*|*'is an alias for'*)
        # Store original alias
        local original_alias="$(whence $cmd)"
        # Remove alias, so that which can return binary
        unalias $cmd
        # Expand original command into full path, to avoid infinite loops
        local expanded_alias="$(echo $original_alias | sed "s%^$cmd%$(\which $cmd)%")"
        # Command is already an alias
        alias $cmd="exec_scmb_expand_args $expanded_alias";;

      *'is a'*'function'*)
        # Copy old function into new name
        eval "$(declare -f $cmd | sed "s/^$cmd ()/__original_$cmd ()/")"
        # Remove function
        unset -f $cmd
        # Create wrapped alias for old function
        alias "$cmd"="exec_scmb_expand_args __original_$cmd";;
      *'is a shell builtin'*) 
        # Handle shell builtin commands
        alias $cmd="exec_scmb_expand_args builtin $cmd";;
      *) 
        # Otherwise, command is a regular script or binary,
        # and the full path can be found from 'which'
        alias $cmd="exec_scmb_expand_args $(\which $cmd)";;
      esac
    done
    # Clean up
    declare -f whence > /dev/null && unset -f whence
  }
  _git_wrap_commands
fi

# Function wrapper around 'll'
# Adds numbered shortcuts to output of ls -l, just like 'git status'
unalias ll > /dev/null 2>&1; unset -f ll > /dev/null 2>&1
function ll {
  # Use ruby to inject numbers into ls output
  ruby -e "$( cat <<EOF
    output = %x(ls -lv --group-directories-first --color)
    output.lines.each_with_index do |line, i|
      puts line.sub(/^(([^ ]* +){8})/, "\\\1\e[2;37m[\e[0m#{i}\e[2;37m]\e[0m" << (i < 10 ? "  " : " "))
    end
EOF
)"

  # Set numbered file shortcut in variable
  local e=1
  for file in $(ls -v --group-directories-first --color=never); do
    export $git_env_char$e="$(readlink -f $file)"
    if [ "${scmbDebug:-}" = "true" ]; then echo "Set \$$git_env_char$e  => $file"; fi
    let e++
  done
}
