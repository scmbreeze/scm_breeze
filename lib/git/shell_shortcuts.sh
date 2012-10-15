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
    for cmd in $(echo $scmb_wrapped_shell_commands); do
      if [ "${scmbDebug:-}" = "true" ]; then echo "SCMB: Wrapping $cmd..."; fi

      case "$(type $cmd 2>&1)" in

      # Don't do anything if command already aliased, or not found.
      *'exec_scmb_expand_args'*)
        if [ "${scmbDebug:-}" = "true" ]; then echo "SCMB: $cmd is already wrapped"; fi;;

      *'not found'*)
        if [ "${scmbDebug:-}" = "true" ]; then echo "SCMB: $cmd not found!"; fi;;

      *'is aliased to'*|*'is an alias for'*)
        if [ "${scmbDebug:-}" = "true" ]; then echo "SCMB: $cmd is an alias"; fi
        # Store original alias
        local original_alias="$(whence $cmd)"
        # Remove alias, so that which can return binary
        unalias $cmd

        # Detect original $cmd type, and escape
        case "$(type $cmd 2>&1)" in
          # Escape shell builtins with 'builtin'
          *'is a shell builtin'*) local escaped_cmd="builtin $cmd";;
          # Get full path for files with 'which'
          *) local escaped_cmd="$(\which $cmd)";;
        esac

        # Expand original command into full path, to avoid infinite loops
        local expanded_alias="$(echo $original_alias | sed "s%\(^\| \)$cmd\($\| \)%\\1$escaped_cmd\\2%")"
        # Wrap previous alias with escaped command
        alias $cmd="exec_scmb_expand_args $expanded_alias";;

      *'is a'*'function'*)
        if [ "${scmbDebug:-}" = "true" ]; then echo "SCMB: $cmd is a function"; fi
        # Copy old function into new name
        eval "$(declare -f $cmd | sed "s/^$cmd ()/__original_$cmd ()/")"
        # Remove function
        unset -f $cmd
        # Create wrapped alias for old function
        alias "$cmd"="exec_scmb_expand_args __original_$cmd";;

      *'is a shell builtin'*)
        if [ "${scmbDebug:-}" = "true" ]; then echo "SCMB: $cmd is a shell builtin"; fi
        # Handle shell builtin commands
        alias $cmd="exec_scmb_expand_args builtin $cmd";;

      *)
        if [ "${scmbDebug:-}" = "true" ]; then echo "SCMB: $cmd is an executable file"; fi
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


# BSD ls is different to Linux (GNU) ls
_uname="$(uname)"
if [ "$_uname" = "Linux" ]; then
  # Linux ls commands
  _ll_command="ls -lhv --group-directories-first --color"
  _ll_sys_command="ls -v --group-directories-first --color=never"
  _abs_path_command="readlink -f"
elif [ "$_uname" = "Darwin" ]; then
  # OS X ls commands
  _ll_command="ls -l -G"
  _ll_sys_command="ls"
  # Use perl abs_path, since readlink -f isn't available on OS X
  _abs_path_command="perl -e 'use Cwd \"abs_path\"; print abs_path(shift)'"
fi

# Replace user/group with user symbol, if defined at ~/.user_sym
# Before : -rw-rw-r-- 1 ndbroadbent ndbroadbent 1.1K Sep 19 21:39 scm_breeze.sh
# After  : -rw-rw-r-- 1 𝐍  𝐍  1.1K Sep 19 21:39 scm_breeze.sh
if [ -e $HOME/.user_sym ]; then
  # Little bit of ruby golf to rejustify the user/group/size columns after replacement
  function rejustify_ls_columns(){
    ruby -e "o=STDIN.read;re=/^(([^ ]* +){2})(([^ ]* +){3})/;u,g,s=o.lines.map{|l|l[re,3]}.compact.map(&:split).transpose.map{|a|a.map(&:size).max+1};puts o.lines.map{|l|l.sub(re){|m|\"%s%-#{u}s %-#{g}s%#{s}s \"%[\$1,*\$3.split]}}"
  }
  _ls_processor="| sed \"s/ $USER/ \$(/bin/cat $HOME/.user_sym)/g\" | rejustify_ls_columns"
fi


if [ -n "$_ll_command" ]; then
  # Function wrapper around 'll'
  # Adds numbered shortcuts to output of ls -l, just like 'git status'
  unalias ll > /dev/null 2>&1; unset -f ll > /dev/null 2>&1
  function ll {
    local ll_output="$(eval $_ll_command $@ $_ls_processor)"

    if [ "$(echo "$ll_output" | wc -l)" -gt "50" ]; then
      echo -e "\e[33mToo many files to create shortcuts. Running plain ll command...\e[0m"
      echo "$ll_output"
      return 1
    fi

    # Use ruby to inject numbers into ls output
    ruby -e "$( cat <<EOF
  output = "$ll_output"
  output.lines.each_with_index do |line, i|
    puts line.sub(/^(([^ ]* +){8})/, "\\\1\e[2;37m[\e[0m#{i}\e[2;37m]\e[0m" << (i < 10 ? "  " : " "))
  end
EOF
)"

    # Set numbered file shortcut in variable
    local e=1
    OLDIFS="$IFS"
    IFS=$(echo -en "\n\b")
    for file in $(eval $_ll_sys_command); do
      export $git_env_char$e="$(eval $_abs_path_command \"$file\")"
      if [ "${scmbDebug:-}" = "true" ]; then echo "Set \$$git_env_char$e  => $file"; fi
      let e++
    done
    IFS="$OLDIFS"
  }
fi

# Alias to list all files
alias la="ll -A"