# ------------------------------------------------------------------------------
# SCM Breeze - Streamline your SCM workflow.
# Copyright 2011 Nathan Broadbent (http://madebynathan.com). All Rights Reserved.
# Released under the LGPL (GNU Lesser General Public License)
# ------------------------------------------------------------------------------

# Wrap common commands with numeric argument expansion.
# Prepends everything with exec_scmb_expand_args,
# even if commands are already aliases or functions
if [ "$shell_command_wrapping_enabled" = "true" ] || [ "$bash_command_wrapping_enabled" = "true" ]; then
  # Do it in a function so we don't bleed variables
  function _git_wrap_commands() {
    # Define 'whence' for bash, to get the value of an alias
    type whence > /dev/null 2>&1 || function whence() { type "$@" | sed -e "s/.*is aliased to \`//" -e "s/'$//"; }
    local cmd=''
    for cmd in $scmb_wrapped_shell_commands; do
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
