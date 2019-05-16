# ------------------------------------------------------------------------------
# SCM Breeze - Streamline your SCM workflow.
# Copyright 2011 Nathan Broadbent (http://madebynathan.com). All Rights Reserved.
# Released under the LGPL (GNU Lesser General Public License)
# ------------------------------------------------------------------------------
#
# bash/zsh 'git_status_shortcuts' implementation, in case Ruby is not installed.
# Of course, I wrote this function first, and then rewrote it in Ruby.
#
# Processes 'git status --porcelain', and exports numbered
# env variables that contain the path of each affected file.
# Output is also more concise than standard 'git status'.
#
# Call with optional <group> parameter to just show one modification state
# # groups => 1: staged, 2: unmerged, 3: unstaged, 4: untracked
# --------------------------------------------------------------------
git_status_shortcuts() {
  zsh_compat # Ensure shwordsplit is on for zsh
  local IFS=$'\n'
  local git_status="$(git status --porcelain 2> /dev/null)"
  local i

  if [ -n "$git_status" ] && [[ $(echo "$git_status" | wc -l) -le $gs_max_changes ]]; then
    unset stat_file; unset stat_col; unset stat_msg; unset stat_grp; unset stat_x; unset stat_y
    # Clear numbered env variables.
    for (( i=1; i<=$gs_max_changes; i++ )); do unset $git_env_char$i; done

    # Get branch
    local branch=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
    # Get project root
    if [ -d .git ]; then
      local project_root="$PWD"
    else
      local project_root=$(git rev-parse --git-dir 2> /dev/null | sed "s%/\.git$%%g")
    fi

    # Colors
    local c_rst="\033[0m"
    local c_branch="\033[1m"
    local c_header="\033[0m"
    local c_dark="\033[2;37m"
    local c_del="\033[0;31m"
    local c_mod="\033[0;32m"
    local c_new="\033[0;33m"
    local c_ren="\033[0;34m"
    local c_cpy="\033[0;33m"
    local c_ign="\033[0;36m"
    # Following colors must be prepended with modifiers e.g. '\033[1;', '\033[0;'
    local c_grp_1="33m"; local c_grp_2="31m"; local c_grp_3="32m"; local c_grp_4="36m"

    local f=1; local e=1  # Counters for number of files, and ENV variables

    echo -e "$c_dark#$c_rst On branch: $c_branch$branch$c_rst  $c_dark|  [$c_rst*$c_dark]$c_rst => \$$git_env_char*\n$c_dark#$c_rst"

    for line in $git_status; do
      if [[ $shell == *bash ]]; then
        x=${line:0:1}; y=${line:1:1}; file=${line:3}
      else
        x=$line[1]; y=$line[2]; file=$line[4,-1]
      fi

      # Index modification states
      msg=""
      case "$x$y" in
      "DD") msg="   both deleted"; col="$c_del"; grp="2";;
      "AU") msg="    added by us"; col="$c_new"; grp="2";;
      "UD") msg="deleted by them"; col="$c_del"; grp="2";;
      "UA") msg="  added by them"; col="$c_new"; grp="2";;
      "DU") msg="  deleted by us"; col="$c_del"; grp="2";;
      "AA") msg="     both added"; col="$c_new"; grp="2";;
      "UU") msg="  both modified"; col="$c_mod"; grp="2";;
      "M"?) msg=" modified"; col="$c_mod"; grp="1";;
      "A"?) msg=" new file"; col="$c_new"; grp="1";;
      "D"?) msg="  deleted"; col="$c_del"; grp="1";;
      "R"?) msg="  renamed"; col="$c_ren"; grp="1";;
      "C"?) msg="   copied"; col="$c_cpy"; grp="1";;
      "??") msg="untracked"; col="$c_ign"; grp="4";;
      esac
      if [ -n "$msg" ]; then
        # Store data at array index and add to group
        stat_file[$f]=$file; stat_msg[$f]=$msg; stat_col[$f]=$col
        stat_grp[$grp]="${stat_grp[$grp]} $f"
        let f++
      fi

      # Work tree modification states
      msg=""
      if [[ "$y" == "M" ]]; then msg=" modified"; col="$c_mod"; grp="3"; fi
      # Don't show {Y} as deleted during a merge conflict.
      if [[ "$y" == "D" && "$x" != "D" && "$x" != "U" ]]; then msg="  deleted"; col="$c_del"; grp="3"; fi
      if [ -n "$msg" ]; then
        stat_file[$f]=$file; stat_msg[$f]=$msg; stat_col[$f]=$col
        stat_grp[$grp]="${stat_grp[$grp]} $f"
        let f++
      fi
    done

    local IFS=" "
    grp_num=1
    for heading in 'Changes to be committed' 'Unmerged paths' 'Changes not staged for commit' 'Untracked files'; do
      # If no group specified as param, or specified group is current group
      if [ -z "$1" ] || [[ "$1" == "$grp_num" ]]; then
        local c_arrow="\033[1;$(eval echo \$c_grp_$grp_num)"
        local c_hash="\033[0;$(eval echo \$c_grp_$grp_num)"
        if [ -n "${stat_grp[$grp_num]}" ]; then
          echo -e "$c_arrow➤$c_header $heading\n$c_hash#$c_rst"
          _gs_output_file_group $grp_num
        fi
      fi
      let grp_num++
    done
  else
    # This function will slow down if there are too many changed files,
    # so just use plain 'git status'
    git status
  fi
  zsh_reset # Reset zsh environment to default
}
# Template function for 'git_status_shortcuts'.
_gs_output_file_group() {
  local relative

  for i in ${stat_grp[$1]}; do
    # Print colored hashes & files based on modification groups
    local c_group="\033[0;$(eval echo -e \$c_grp_$1)"

    # Deduce relative path based on current working directory
    if [ -z "$project_root" ]; then
      relative="${stat_file[$i]}"
    else
      local absolute="$project_root/${stat_file[$i]}"
      local dest=$(readlink -f "$absolute")
      local pwd=$(readlink -f "$PWD")
      relative="$(_gs_relative_path "$pwd" "${dest:-$absolute}" )"
    fi

    if [[ $f -gt 10 && $e -lt 10 ]]; then local pad=" "; else local pad=""; fi   # (padding)
    echo -e "$c_hash#$c_rst     ${stat_col[$i]}${stat_msg[$i]}:\
$pad$c_dark [$c_rst$e$c_dark] $c_group$relative$c_rst"
    # Export numbered variables in the order they are displayed.
    # (Exports full path, but displays relative path)
    # fetch first file (in the case of oldFile -> newFile) and remove quotes
    local filename=$(eval echo $(echo ${stat_file[$i]} | egrep -o '^"([^\\"]*(\\.[^"]*)*)"|^[^ ]+'))
    export $git_env_char$e="$project_root/$filename"
    let e++
  done
  echo -e "$c_hash#$c_rst"
}

# Show relative path if current directory is not project root
_gs_relative_path(){
  # Credit to 'pini' for the following script.
  # (http://stackoverflow.com/questions/2564634/bash-convert-absolute-path-into-relative-path-given-a-current-directory)
  target=$2; common_part=$1; back=""
  while [[ -n "${common_part}" && "${target#$common_part}" == "${target}" ]]; do
    common_part="${common_part%/*}"
    back="../${back}"
  done
  echo "${back}${target#$common_part/}"
}

