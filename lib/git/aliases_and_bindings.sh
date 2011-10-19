#
# Set up configured aliases & keyboard shortcuts
# --------------------------------------------------------------------
# _alias() ignores errors if alias is not defined. (from lib/scm_breeze.sh)

_alias $git_alias='git'

# SCM Breeze functions
_alias $git_status_shortcuts_alias="git_status_shortcuts"
_alias $git_add_shortcuts_alias="git_add_shorcuts"
_alias $exec_git_expand_args_alias="exec_git_expand_args"
_alias $git_show_files_alias="git_show_affected_files"
_alias $git_commit_all_alias='git_commit_all'

# Expand numbers and ranges for commands that deal with paths
_exp="exec_git_expand_args"
_alias $git_checkout_alias="$_exp git checkout"
_alias $git_commit_alias="$_exp git commit"
_alias $git_reset_alias="$_exp git reset"
_alias $git_rm_alias="$_exp git rm"
_alias $git_blame_alias="$_exp git blame"
_alias $git_diff_alias="$_exp git diff"
_alias $git_diff_cached_alias="$_exp git diff --cached"

# Standard commands
_alias $git_clone_alias='git clone'
_alias $git_fetch_alias='git fetch'
_alias $git_fetch_and_rebase_alias='git fetch && git rebase'
_alias $git_pull_alias='git pull'
_alias $git_push_alias='git push'
_alias $git_status_original_alias='git status' # (Standard git status)
_alias $git_status_short_alias='git status -s'
_alias $git_remote_alias='git remote -v'
_alias $git_branch_alias='git branch'
_alias $git_branch_all_alias='git branch -a'
_alias $git_rebase_alias='git rebase'
_alias $git_merge_alias='git merge'
_alias $git_cherry_pick_alias='git cherry-pick'
_alias $git_log_alias='git log'
_alias $git_log_stat_alias='git log --stat --max-count=5'
_alias $git_log_graph_alias='git log --graph --max-count=5'
_alias $git_show_alias='git show'
_alias $git_add_all_alias='git add -A'
_alias $git_commit_amend_alias='git commit --amend'
# Add staged changes to latest commit without prompting for message
_alias $git_commit_amend_no_msg_alias='git commit --amend -C HEAD'

# Git Index alias
_alias $git_index_alias="git_index"


# Tab completion for aliases
if [[ $shell == "zsh" ]]; then
  # Turn on support for bash completion
  autoload bashcompinit
  bashcompinit

  # -- zsh
  compdef $git_alias=git
  compdef _git $git_pull_alias=git-pull
  compdef _git $git_push_alias=git-push
  compdef _git $git_fetch_alias=git-fetch
  compdef _git $git_fetch_and_rebase_alias=git-fetch
  compdef _git $git_diff_alias=git-diff
  compdef _git $git_commit_alias=git-commit
  compdef _git $git_commit_all_alias=git-commit
  compdef _git $git_checkout_alias=git-checkout
  compdef _git $git_branch_alias=git-branch
  compdef _git $git_branch_all_alias=git-branch
  compdef _git $git_log_alias=git-log
  compdef _git $git_log_stat_alias=git-log
  compdef _git $git_log_graph_alias=git-log
  compdef _git $git_add_shortcuts_alias=git-add
  compdef _git $git_merge_alias=git-merge
else
  # -- bash
  complete -o default -o nospace -F _git          $git_alias
  complete -o default -o nospace -F _git_pull     $git_pull_alias
  complete -o default -o nospace -F _git_push     $git_push_alias
  complete -o default -o nospace -F _git_fetch    $git_fetch_alias
  complete -o default -o nospace -F _git_branch   $git_branch_alias
  complete -o default -o nospace -F _git_rebase   $git_rebase_alias
  complete -o default -o nospace -F _git_merge    $git_merge_alias
  complete -o default -o nospace -F _git_log      $git_log_alias
  complete -o default -o nospace -F _git_diff     $git_diff_alias
  complete -o default -o nospace -F _git_checkout $git_checkout_alias
  complete -o default -o nospace -F _git_remote   $git_remote_alias
  complete -o default -o nospace -F _git_show     $git_show_alias
fi

# Git repo management & aliases.
# If you know how to rewrite _git_index_tab_completion() for zsh, please send me a pull request!
complete -o nospace -o filenames -F _git_index_tab_completion git_index
complete -o nospace -o filenames -F _git_index_tab_completion $git_index_alias


# Keyboard Bindings
# -----------------------------------------------------------
# 'git_commit_all' and 'git_add_and_commit' give commit message prompts.
# See [here](http://qntm.org/bash#sec1) for info about why I wanted a prompt.

# Cross-shell key bindings
_bind(){
  if [[ $shell == "zsh" ]]; then # zsh
    bindkey -s "$1" "$2"
  else # bash
    bind "\"$1\": \"$2\""
  fi
}

case "$TERM" in
xterm*|rxvt*)
    # CTRL-SPACE => $  git_status_shortcuts {ENTER}
    _bind "$git_status_shortcuts_keys" " git_status_shortcuts\n"
    # CTRL-x-SPACE => $  git_commit_all {ENTER}
    _bind "$git_commit_all_keys" " git_commit_all\n"
    # CTRL-x-c => $  git_add_and_commit {ENTER}
    # 1 3 CTRL-x-c => $  git_add_and_commit 1 3 {ENTER}
    _bind "$git_add_and_commit_keys" "\e[1~ git_add_and_commit \n"

    # Commands are prepended with a space so that they won't be added to history.
    # Make sure this is turned on with:
    # zsh:  setopt histignorespace histignoredups
    # bash: HISTCONTROL=ignorespace:ignoredups
esac

