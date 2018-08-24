# ------------------------------------------------------------------------------
# SCM Breeze - Streamline your SCM workflow.
# Copyright 2011 Nathan Broadbent (http://madebynathan.com). All Rights Reserved.
# Released under the LGPL (GNU Lesser General Public License)
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Numbered shortcuts for git branch
# ------------------------------------------------------------------------------

# Function wrapper around 'll'
# Adds numbered shortcuts to output of ls -l, just like 'git status'
unalias $git_branch_alias > /dev/null 2>&1; unset -f $git_branch_alias > /dev/null 2>&1
function _scmb_git_branch_shortcuts {
  fail_if_not_git_repo || return 1

  # Fall back to normal git branch, if any unknown args given
  if [[ "$($_git_cmd branch | wc -l)" -gt 300 ]] || ([[ -n "$@" ]] && [[ "$@" != "-a" ]]); then
    exec_scmb_expand_args $_git_cmd branch "$@"
    return 1
  fi

  # Use ruby to inject numbers into ls output
  ruby -e "$( cat <<EOF
    output = %x($_git_cmd branch --color=always "$@")
    line_count = output.lines.to_a.size
    output.lines.each_with_index do |line, i|
      spaces = (line_count > 9 && i < 9 ? "  " : " ")
      puts line.sub(/^([ *]{2})/, "\\\1\033[2;37m[\033[0m#{i+1}\033[2;37m]\033[0m" << spaces)
    end
EOF
)"

  # Set numbered file shortcut in variable
  local e=1
  IFS=$'\n'
  for branch in $($_git_cmd branch "$@" | sed "s/^[* ]\{2\}//"); do
    export $git_env_char$e="$branch"
    if [ "${scmbDebug:-}" = "true" ]; then echo "Set \$$git_env_char$e  => $file"; fi
    let e++
  done
  unset IFS
}

__git_alias "$git_branch_alias"              "_scmb_git_branch_shortcuts" ""
__git_alias "$git_branch_all_alias"          "_scmb_git_branch_shortcuts" "-a"
__git_alias "$git_branch_move_alias"         "_scmb_git_branch_shortcuts" "-m"
__git_alias "$git_branch_delete_alias"       "_scmb_git_branch_shortcuts" "-d"
__git_alias "$git_branch_delete_force_alias" "_scmb_git_branch_shortcuts" "-D"

# Define completions for git branch shortcuts
if [ "$shell" = "bash" ]; then
  for alias_str in $git_branch_alias $git_branch_all_alias $git_branch_move_alias $git_branch_delete_alias; do
    __define_git_completion $alias_str branch
    complete -o default -o nospace -F _git_"$alias_str"_shortcut $alias_str
  done
fi
