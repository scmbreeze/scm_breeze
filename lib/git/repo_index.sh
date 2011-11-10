# -------------------------------------------------------
# SCM Breeze - Streamline your SCM workflow.
# Copyright 2011 Nathan Broadbent (http://madebynathan.com). All Rights Reserved.
# Released under the LGPL (GNU Lesser General Public License)
# -------------------------------------------------------

# -------------------------------------------------------
# Repository Index scripts for Git projects
# -------------------------------------------------------


# * The `git_index` function makes it easy to list & switch between
#   git projects in $GIT_REPO_DIR (default = ~/src)
#
#   * Change directory to any of your git repos or submodules, with recursive tab completion.
#
#   * A repository index will be created at $GIT_REPO_DIR/.git_index
#     (Scanning for git projects and submodules can take a few seconds.)
#
#   * Cache can be rebuilt by running:
#       $ git_index --rebuild
#       ('--' commands have tab completion too.)
#
#   * Ignores projects within an 'archive' folder.
#
#   * Allows you to run batch commands across all your repositories:
#
#     - Update every repo from their remote: 'git_index --update-all'
#     - Produce a count of repos for each host: 'git_index --count-by-host'
#     - Run a custom command for each repo: 'git_index --batch-cmd <command>'
#
# Examples:
#
#     $ git_index --list
#     # => Lists all git projects
#
#     $ git_index ub[TAB]
#     # => Provides tab completion for all project folders that begin with 'ub'
#
#     $ git_index ubuntu_config
#     # => Changes directory to ubuntu_config, and auto-updates code from git remote.
#
#     $ git_index buntu_conf
#     # => Same result as `git_index ubuntu_config`
#
#     $ git_index
#     # => cd $GIT_REPO_DIR


function git_index() {
  local IFS=$'\n'
  if [ -z "$1" ]; then
    # Just change to $GIT_REPO_DIR if no params given.
    cd $GIT_REPO_DIR
  else
    if [ "$1" = "--rebuild" ]; then
      _rebuild_git_index
    elif [ "$1" = "--update-all" ]; then
      _git_index_update_all
    elif [ "$1" = "--batch-cmd" ]; then
      _git_index_batch_cmd "${@:2:$(($#-1))}" # Pass all args except $1
    elif [ "$1" = "--list" ] || [ "$1" = "-l" ]; then
      echo -e "$_bld_col$(_git_index_count)$_txt_col Git repositories in $_bld_col$GIT_REPO_DIR$_txt_col:\n"
      for repo in $(_git_index_dirs_without_home); do
        echo $(basename $repo) : $repo
      done | sort | column -t -s ':'
    elif [ "$1" = "--count-by-host" ]; then
      echo -e "=== Producing a report of the number of repos per host...\n"
      _git_index_batch_cmd git remote -v | grep "origin.*(fetch)" |
      sed -e "s/origin\s*//" -e "s/(fetch)//" |
      sed -e "s/\(\([^/]*\/\/\)\?\([^@]*@\)\?\([^:/]*\)\).*/\1/" |
      sort | uniq -c
      echo
    else
      _check_git_index
      # Figure out which directory we need to change to.
      local project=$(echo $1 | cut -d "/" -f1)
      # Find base path of project
      local base_path="$(grep "/$project$" "$GIT_REPO_DIR/.git_index")"
      if [ -n "$base_path" ]; then
        sub_path=$(echo $1 | sed "s:^$project::")
        # Append subdirectories to base path
        base_path="$base_path$sub_path"
      fi
      # Try partial matches
      # - string at beginning of project
      if [ -z "$base_path" ]; then base_path=$(_git_index_dirs_without_home | grep -m1 "/$project"); fi
      # - string anywhere in project
      if [ -z "$base_path" ]; then base_path=$(_git_index_dirs_without_home | grep -m1 "$project"); fi
      # --------------------
      # Go to our base path
      if [ -n "$base_path" ]; then
        unset IFS
        # evaluate ~ if necessary
        if [[ "$base_path" == "~"* ]]; then
          base_path=$(eval echo ${base_path%%/*})/${base_path#*/}
        fi
        cd "$base_path"
        # Run git callback (either update or show changes), if we are in the root directory
        if [ -z "${sub_path%/}" ]; then _git_index_update_or_status; fi
      else
        echo -e "$_wrn_col'$1' did not match any git repos in $GIT_REPO_DIR$_txt_col"
      fi
    fi
  fi
}

_git_index_dirs_without_home() {
  sed -e "s/--.*//" -e "s%$HOME%~%" $GIT_REPO_DIR/.git_index
}

# Recursively searches for git repos in $GIT_REPO_DIR
function _find_git_repos() {
  # Find all unarchived projects
  local IFS=$'\n'
  for repo in $(find "$GIT_REPO_DIR" -maxdepth 4 -name ".git" -type d \! -wholename '*/archive/*'); do
    echo ${repo%/.git}          # Return project folder, with trailing ':'
    _find_git_submodules $repo  # Detect any submodules
  done
}

# List all submodules for a git repo, if any.
function _find_git_submodules() {
  if [ -e "$1/../.gitmodules" ]; then
    grep "\[submodule" "$1/../.gitmodules" | sed "s%\[submodule \"%${1%/.git}/%g" | sed "s/\"]//g"
  fi
}


# Rebuilds index of git repos in $GIT_REPO_DIR.
function _rebuild_git_index() {
  if [ "$1" != "--silent" ]; then echo -e "== Scanning $GIT_REPO_DIR for git repos & submodules..."; fi
  # Get repos from src dir and custom dirs, then sort by basename
  local IFS=$'\n'
  for repo in $(echo -e "$(_find_git_repos)\n$(echo $GIT_REPOS | sed "s/:/\\\\n/g")"); do
    echo $(basename $repo | sed "s/ /_/g") $repo
  done | sort | cut -d " " -f2- > "$GIT_REPO_DIR/.git_index"

  if [ "$1" != "--silent" ]; then
    echo -e "===== Indexed $_bld_col$(_git_index_count)$_txt_col repos in $GIT_REPO_DIR/.git_index"
  fi
}

# Build index if empty
function _check_git_index() {
  if [ ! -f "$GIT_REPO_DIR/.git_index" ]; then
    _rebuild_git_index --silent
  fi
}

# Produces a count of repos in the tab completion index (excluding commands)
function _git_index_count() {
  echo $(sed -e "s/--.*//" "$GIT_REPO_DIR/.git_index" | grep . | wc -l)
}

# Returns the current git branch (returns nothing if not a git repository)
parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

# If the working directory is clean, update the git repository. Otherwise, show changes.
function _git_index_update_or_status() {
  if ! [ `git status --porcelain | wc -l` -eq 0 ]; then
    # Fall back to 'git status' if git status alias isn't configured
    if type $git_status_command 2>&1 | grep -qv "not found"; then
      eval $git_status_command
    else
      git status
    fi
  else
    # Check that a local 'origin' remote exists.
    if (git remote -v | grep -q origin); then
      # Only update the git repo if it hasn't been touched for at least 6 hours.
      if $(find ".git" -maxdepth 0 -type d -mmin +360 | grep -q "\.git"); then
        _git_index_update_branch_or_master
      fi
    fi
  fi
}

_git_index_update_branch_or_master() {
  branch=$(parse_git_branch)
  # If we aren't on any branch, checkout master.
  if [ "$branch" = "(no branch)" ]; then
    echo -e "=== Checking out$_git_col master$_txt_col branch."
    git checkout master
    branch="master"
  fi
  echo -e "=== Updating '$branch' branch in $_bld_col$base_path$_txt_col from$_git_col origin$_txt_col... (Press Ctrl+C to cancel)"
  # Pull the latest code from the server
  git pull origin $branch
}

# Updates all git repositories with clean working directories.
function _git_index_update_all() {
  echo -e "== Updating code in $_bld_col$(_git_index_count)$_txt_col repos...\n"
  _git_index_batch_cmd _git_index_update_branch_or_master
}

# Runs a command for all git repos
function _git_index_batch_cmd() {
  cwd="$PWD"
  if [ -n "$1" ]; then
    echo -e "== Running command for $_bld_col$(_git_index_count)$_txt_col repos...\n"
    unset IFS
    for base_path in $(sed -e "s/--.*//" "$GIT_REPO_DIR/.git_index" | grep . | sort); do
      cd "$base_path"
      $@
    done
  else
    echo "Please give a command to run for all repos. (It may be useful to write your command as a function or script.)"
  fi
  cd "$cwd"
}


# Bash tab completion function for git_index()
function _git_index_tab_completion() {
  _check_git_index
  local curw
  local IFS=$'\n'
  COMPREPLY=()
  curw=${COMP_WORDS[COMP_CWORD]}

  # If the first part of $curw matches a high-level directory,
  # then match on sub-directories for that project
  local project=$(echo "$curw" | cut -d "/" -f1)
  local base_path=$(grep "/$project$" "$GIT_REPO_DIR/.git_index" | sed 's/ /\\ /g')

  # If matching path was found and curr string contains a /, then complete project sub-directories
  if [[ -n "$base_path" && $curw == */* ]]; then
    local search_path=$(echo "$curw" | sed "s:^${project/\\/\\\\\\}::")
    COMPREPLY=($(compgen -d "$base_path$search_path" | grep -v "/.git" | sed -e "s:$base_path:$project:" -e "s:$:/:" ))
  # Else, tab complete all the entries in .git_index, plus '--' commands
  else
    local commands="--list\n--rebuild\n--update-all\n--batch-cmd\n--count-by-host"
    COMPREPLY=($(compgen -W '$(sed -e "s:.*/::" -e "s:$:/:" "$GIT_REPO_DIR/.git_index" | sort)$(echo -e "\n"$commands)' -- $curw))
  fi
  return 0
}

