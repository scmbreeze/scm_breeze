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
    return $?
  fi

  # Use ruby to inject numbers into git branch output
  ruby -e "$(
    cat <<EOF
    def build_worktree_to_branch_map(git_cmd)
      worktree_map = {}
      worktree_output = %x(#{git_cmd} worktree list --porcelain 2>/dev/null)
      current_worktree = nil
      worktree_output.lines.each do |line|
        if line.start_with?('worktree ')
          current_worktree = line[9..-1].strip
        elsif line.start_with?('branch refs/heads/') && current_worktree
          branch_name = line[18..-1].strip
          worktree_map[branch_name] = current_worktree
          current_worktree = nil
        end
      end
      worktree_map
    end

    def extract_branch_name(line)
      line.strip.gsub(/^\*\s+|^\+\s+|\s+/, '').gsub(/\e\[[0-9;]*m/, '')
    end

    def strip_ansi_codes(str)
      str.gsub(/\e\[[0-9;]*m/, '')
    end

    def find_current_branch(output)
      output.lines.each do |line|
        return extract_branch_name(line) if line.start_with?('* ')
      end
      nil
    end

    def calculate_max_branch_width(output, line_count, current_branch, worktree_map)
      max_width = 0
      output.lines.each_with_index do |line, i|
        branch_name = extract_branch_name(line)

        if worktree_map[branch_name] && branch_name != current_branch
          # Add extra space for single-digit numbers when we have 10+ branches
          number_spacing = (line_count > 9 && i < 9) ? '  ' : ' '
          numbered_line = line.sub(/^([ *+]{2})/, "\\\1\033[2;37m[\033[0m#{i+1}\033[2;37m]\033[0m" << number_spacing)
          width = strip_ansi_codes(numbered_line.chomp).length
          max_width = width if width > max_width
        end
      end
      max_width
    end

    def format_branch_line(line, index, line_count, branch_name, current_branch, worktree_map, max_width, show_worktrees)
      # Add extra space for single-digit numbers when we have 10+ branches
      number_spacing = (line_count > 9 && index < 9) ? '  ' : ' '

      # Insert branch number after the leading marker (* or +)
      formatted = line.sub(/^([ *+]{2})/, "\\\1\033[2;37m[\033[0m#{index+1}\033[2;37m]\033[0m" << number_spacing)

      # Append worktree path if we have multiple worktrees and this isn't the current branch
      if show_worktrees && worktree_map[branch_name] && branch_name != current_branch
        current_width = strip_ansi_codes(formatted.chomp).length
        padding = ' ' * (max_width - current_width)
        formatted = formatted.chomp + padding + " \033[2;37m(#{worktree_map[branch_name]})\033[0m\n"
      end

      formatted
    end

    output = %x($_git_cmd branch --color=always $(token_quote "$@"))
    worktree_map = build_worktree_to_branch_map('$_git_cmd')
    line_count = output.lines.to_a.size
    current_branch = find_current_branch(output)

    show_worktrees = worktree_map.size > 1

    # Align the parenthesis in worktree output
    max_width = show_worktrees ? calculate_max_branch_width(output, line_count, current_branch, worktree_map) : 0

    output.lines.each_with_index do |line, i|
      branch_name = extract_branch_name(line)
      formatted_line = format_branch_line(line, i, line_count, branch_name, current_branch, worktree_map, max_width, show_worktrees)
      puts formatted_line
    end
EOF
)"

  # Set numbered file shortcut in variable
  local e=1 IFS=$'\n'
  for branch in $($_git_cmd branch "$@" | sed "s/^[*+ ]\{2\}//"); do
    export $GIT_ENV_CHAR$e="$branch"
    if [ "${scmbDebug:-}" = "true" ]; then echo "Set \$$GIT_ENV_CHAR$e  => $file"; fi
    let e++
  done
}

function _scmb_git_checkout_shortcuts {
  fail_if_not_git_repo || return 1

  if [ -z "$1" ]; then
    exec_scmb_expand_args $_git_cmd checkout
    return $?
  fi

  if [[ "$1" =~ ^[0-9]+$ ]]; then
    local branch_var="${git_env_char}$1"
    local branch=$(eval echo "\$$branch_var")

    if [ -n "$branch" ]; then
      if $_git_cmd worktree list --porcelain 2>/dev/null | grep -q "^branch refs/heads/$branch$"; then
        local worktree_path=$($_git_cmd worktree list --porcelain | awk "
          /^worktree / {
            path = substr(\$0, 10); next
          }
          /^branch refs\/heads\/$branch$/ {
            print path; exit
          }
        ")
        if [ -n "$worktree_path" ] && [ -d "$worktree_path" ]; then
          echo "Switching to worktree: $worktree_path"
          cd "$worktree_path"
          return $?
        fi
      fi
    fi
  fi

  exec_scmb_expand_args $_git_cmd checkout "$@"
}

__git_alias "$git_branch_alias"              "_scmb_git_branch_shortcuts" ""
__git_alias "$git_branch_all_alias"          "_scmb_git_branch_shortcuts" "-a"
__git_alias "$git_branch_move_alias"         "_scmb_git_branch_shortcuts" "-m"
__git_alias "$git_branch_delete_alias"       "_scmb_git_branch_shortcuts" "-d"
__git_alias "$git_branch_delete_force_alias" "_scmb_git_branch_shortcuts" "-D"

# Define completions for git branch shortcuts
if [ "$GIT_SKIP_SHELL_COMPLETION" != "yes" ]; then
  if breeze_shell_is "bash"; then
    for alias_str in $git_branch_alias $git_branch_all_alias $git_branch_move_alias $git_branch_delete_alias; do
      __define_git_completion $alias_str branch
      complete -o default -o nospace -F _git_"$alias_str"_shortcut $alias_str
    done
  fi
fi
