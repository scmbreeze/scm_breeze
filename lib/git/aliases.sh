# ------------------------------------------------------------------------------
# SCM Breeze - Streamline your SCM workflow.
# Copyright 2011 Nathan Broadbent (http://madebynathan.com). All Rights Reserved.
# Released under the LGPL (GNU Lesser General Public License)
# ------------------------------------------------------------------------------

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
export _git_cmd="$(bin_path git)"
# Wrap git with the 'hub' github wrapper, if installed (https://github.com/defunkt/hub)
if type hub > /dev/null 2>&1; then export _git_cmd="hub"; fi

# gh is now deprecated, and merged into the `hub` command line tool.
#if type gh  > /dev/null 2>&1; then export _git_cmd="gh"; fi

# Create 'git' function that calls hub if defined, and expands all numeric arguments
function git(){
  # Only expand args for git commands that deal with paths or branches
  case $1 in
    commit|blame|add|log|rebase|merge|difftool|switch)
      exec_scmb_expand_args "$_git_cmd" "$@";;
    checkout|diff|rm|reset|restore)
      exec_scmb_expand_args --relative "$_git_cmd" "$@";;
    branch)
      _scmb_git_branch_shortcuts "${@:2}";;
    *)
      "$_git_cmd" "$@";;
  esac
}

_alias "$git_alias" "git"


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
__git_wrap__git_main
}
"
}

# Define git alias with tab completion
# Usage: __git_alias <alias> <command_prefix> <command>
__git_alias () {
  if [ -n "$1" ]; then
    local alias_str cmd_prefix cmd cmd_args

    alias_str="$1"; cmd_prefix="$2"; cmd="$3";
    if [ $# -gt 2 ]; then
      shift 3 2>/dev/null
      cmd_args=("$@")
    fi

    alias $alias_str="$cmd_prefix $cmd${cmd_args:+ }${cmd_args[*]}"
    if [ "$shell" = "bash" ]; then
      __define_git_completion "$alias_str" "$cmd"
      complete -o default -o nospace -F _git_"$alias_str"_shortcut "$alias_str"
    fi
  fi
}

# --------------------------------------------------------------------
# SCM Breeze functions
_alias "$git_status_shortcuts_alias"  'git_status_shortcuts'
_alias "$git_add_shortcuts_alias"     'git_add_shortcuts'
_alias "$exec_scmb_expand_args_alias" 'exec_scmb_expand_args'
_alias "$git_show_files_alias"        'git_show_affected_files'
_alias "$git_commit_all_alias"        'git_commit_all'
_alias "$git_grep_shortcuts_alias"    'git_grep_shortcuts'

# Git Index alias
_alias "$git_index_alias"             'git_index'

# Only set up the following aliases if 'git_setup_aliases' is 'yes'
if [ "$git_setup_aliases" = "yes" ]; then

  # Commands that deal with paths
  __git_alias "$git_checkout_alias"                 'git' 'checkout'
  __git_alias "$git_commit_alias"                   'git' 'commit'
  __git_alias "$git_commit_verbose_alias"           'git' 'commit' '--verbose'
  __git_alias "$git_reset_alias"                    'git' 'reset'
  __git_alias "$git_reset_hard_alias"               'git' 'reset' '--hard'
  __git_alias "$git_rm_alias"                       'git' 'rm'
  __git_alias "$git_blame_alias"                    'git' 'blame'
  __git_alias "$git_diff_no_whitespace_alias"       'git' 'diff' '-w'
  __git_alias "$git_diff_alias"                     'git' 'diff'
  __git_alias "$git_diff_file_alias"                'git' 'diff'
  __git_alias "$git_diff_word_alias"                'git' 'diff' '--word-diff'
  __git_alias "$git_diff_cached_alias"              'git' 'diff' '--cached'
  __git_alias "$git_add_patch_alias"                'git' 'add' '-p'
  __git_alias "$git_add_updated_alias"              'git' 'add' '-u'
  __git_alias "$git_difftool_alias"                 'git' 'difftool'
  __git_alias "$git_mergetool_alias"                'git' 'mergetool'
  __git_alias "$git_restore_alias"                  'git' 'restore'

  # Custom default format for git log
  git_log_command="log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
  __git_alias "$git_log_alias"                      'git' "$git_log_command"

  # Same as the above, but displays all the branches and remotes
  __git_alias "$git_log_all_alias"                  'git' "$git_log_command" '--branches' '--remotes'

  # Standard commands
  __git_alias "$git_clone_alias"                    'git' 'clone'
  __git_alias "$git_fetch_alias"                    'git' 'fetch'
  __git_alias "$git_checkout_branch_alias"          'git' 'checkout' '-b'
  __git_alias "$git_pull_alias"                     'git' 'pull'
  __git_alias "$git_pull_rebase_alias"              'git' 'pull' '--rebase'
  __git_alias "$git_push_alias"                     'git' 'push'
  __git_alias "$git_push_force_alias"               'git' 'push' '-f'
  __git_alias "$git_status_original_alias"          'git' 'status' # (Standard git status)
  __git_alias "$git_status_short_alias"             'git' 'status' '-s'
  __git_alias "$git_clean_alias"                    'git' 'clean'
  __git_alias "$git_clean_force_alias"              'git' 'clean' '-fd'
  __git_alias "$git_remote_alias"                   'git' 'remote' '-v'
  __git_alias "$git_rebase_alias"                   'git' 'rebase'
  __git_alias "$git_rebase_interactive_alias"       'git' 'rebase' '-i'
  __git_alias "$git_rebase_alias_continue"          'git' 'rebase' '--continue'
  __git_alias "$git_rebase_alias_abort"             'git' 'rebase' '--abort'
  __git_alias "$git_reset_last_commit"              'git' 'reset HEAD~'
  __git_alias "$git_top_level_alias"                'git' 'rev-parse' '--show-toplevel'
  __git_alias "$git_merge_alias"                    'git' 'merge'
  __git_alias "$git_merge_no_fast_forward_alias"    'git' 'merge' '--no-ff'
  __git_alias "$git_merge_only_fast_forward_alias"  'git' 'merge' '--ff'
  __git_alias "$git_cherry_pick_alias"              'git' 'cherry-pick'
  __git_alias "$git_show_alias"                     'git' 'show'
  __git_alias "$git_show_summary"                   'git' 'show' '--summary'
  __git_alias "$git_stash_alias"                    'git' 'stash'
  __git_alias "$git_stash_apply_alias"              'git' 'stash' 'apply'
  __git_alias "$git_stash_pop_alias"                'git' 'stash' 'pop'
  __git_alias "$git_stash_list_alias"               'git' 'stash' 'list'
  __git_alias "$git_tag_alias"                      'git' 'tag'
  __git_alias "$git_submodule_update_alias"         'git' 'submodule' 'update' '--init'
  __git_alias "$git_submodule_update_rec_alias"     'git' 'submodule' 'update' '--init' '--recursive'
  __git_alias "$git_whatchanged_alias"              'git' 'whatchanged'
  __git_alias "$git_apply_alias"                    'git' 'apply'
  __git_alias "$git_switch_alias"                   'git' 'switch'

  # Compound/complex commands
  _alias "$git_fetch_all_alias"           'git fetch --all'
  _alias "$git_pull_then_push_alias"      'git pull && git push'
  _alias "$git_fetch_and_rebase_alias"    'git fetch && git rebase'
  _alias "$git_commit_amend_alias"        'git commit --amend'

  # Add staged changes to latest commit without prompting for message
  _alias "$git_commit_amend_no_msg_alias" 'git commit --amend -C HEAD'
  _alias "$git_commit_no_msg_alias"       'git commit -C HEAD'
  _alias "$git_log_stat_alias"            'git log --stat --max-count=5'
  _alias "$git_log_graph_alias"           'git log --graph --max-count=5'
  _alias "$git_add_all_alias"             'git add --all .'

  # Hub aliases (https://github.com/github/hub)
  _alias "$git_pull_request_alias"        'git pull-request'
fi



# Tab completion
if [ $shell = "bash" ]; then
  # Fix to preload Arch bash completion for git
  [[ -s "/usr/share/git/completion/git-completion.bash" ]] && source "/usr/share/git/completion/git-completion.bash"
  # new path in Ubuntu 13.04
  [[ -s "/usr/share/bash-completion/completions/git" ]] && source "/usr/share/bash-completion/completions/git"
  complete -o default -o nospace -F __git_wrap__git_main $git_alias

  # Git repo management & aliases.
  # If you know how to rewrite _git_index_tab_completion() for zsh, please send me a pull request!
  complete -o nospace -F _git_index_tab_completion git_index
  complete -o nospace -F _git_index_tab_completion $git_index_alias
else
  compdef _git_index_tab_completion git_index $git_index_alias
fi
