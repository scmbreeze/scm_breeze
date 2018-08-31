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
#   * You can also change to a top-level directory within $GIT_REPO_DIR by prefixing the argument
#     with '/'
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
  IFS=$'\n'
  if [ -z "$1" ]; then
    # Just change to $GIT_REPO_DIR if no params given.
    "cd" $GIT_REPO_DIR
  else
    if [ "$1" = "--rebuild" ]; then
      _rebuild_git_index
    elif [ "$1" = "--update-all" ]; then
      _git_index_update_all
    elif [ "$1" = "--update-all-with-notifications" ]; then
      NOTIFY=true
      _git_index_update_all
    elif [ "$1" = "--batch-cmd" ]; then
      _git_index_batch_cmd "${@:2:$(($#-1))}" # Pass all args except $1
    elif [ "$1" = "--list" ] || [ "$1" = "-l" ]; then
      echo -e "$_bld_col$(_git_index_count)$_txt_col Git repositories in $_bld_col$GIT_REPO_DIR$_txt_col:\n"
      for repo in $(_git_index_dirs_without_home); do
        echo $(basename $repo | sed "s/ /_/g") : $repo
      done | sort -t ":" -k1,1 | column -t -s ':'
    elif [ "$1" = "--count-by-host" ]; then
      echo -e "=== Producing a report of the number of repos per host...\n"
      _git_index_batch_cmd git remote -v | \grep "origin.*(fetch)" |
      sed -e "s/origin\s*//" -e "s/(fetch)//" |
      sed -e "s/\(\([^/]*\/\/\)\?\([^@]*@\)\?\([^:/]*\)\).*/\1/" |
      sort | uniq -c
      echo

    # If $1 starts with '/', change to top-level directory within $GIT_REPO_DIR
    elif ([ $shell = "bash" ] && [ "${1:0:1}" = "/" ]) || \
         ([ $shell = "zsh" ]  && [ "${1[1]}"  = "/" ]); then
      if [ -d "$GIT_REPO_DIR$1" ]; then
        builtin cd "$GIT_REPO_DIR$1"
      fi
    else
      _check_git_index
      # Figure out which directory we need to change to.
      local project=$(echo $1 | cut -d "/" -f1)
      # Find base path of project
      local base_path="$(\grep -m1 "/$project$" "$GIT_REPO_DIR/.git_index")"
      if [ -n "$base_path" ]; then
        sub_path=$(echo $1 | sed "s:^$project::")
        # Append subdirectories to base path
        base_path="$base_path$sub_path"
      fi
      # Try partial matches
      # - string at beginning of project
      if [ -z "$base_path" ]; then base_path=$(_git_index_dirs_without_home | \grep -m1 -i "/$project"); fi
      # - string anywhere in project
      if [ -z "$base_path" ]; then base_path=$(_git_index_dirs_without_home | \grep -m1 -i "$project"); fi
      # --------------------
      # Go to our base path
      if [ -n "$base_path" ]; then
        IFS=$' \t\n'
        # evaluate ~ if necessary
        if [[ "$base_path" == "~"* ]]; then
          base_path=$(eval echo ${base_path%%/*})/${base_path#*/}
        fi
        cd "$base_path"
        # Run git callback (either update or show changes), if we are in the root directory
        if [ -z "${sub_path%/}" ]; then _git_index_status_if_dirty; fi
      else
        echo -e "$_wrn_col'$1' did not match any git repos in $GIT_REPO_DIR$_txt_col"
      fi
    fi
  fi
  unset IFS
}

_git_index_dirs_without_home() {
  sed -e "s/--.*//" -e "s%$HOME%~%" $GIT_REPO_DIR/.git_index
}

# Recursively searches for git repos in $GIT_REPO_DIR
function _find_git_repos() {
  # Find all unarchived projects
  IFS=$'\n'
  for repo in $(find -L "$GIT_REPO_DIR" -maxdepth 5 -name ".git" -type d \! -wholename '*/archive/*'); do
    echo ${repo%/.git}          # Return project folder, with trailing ':'
    _find_git_submodules $repo  # Detect any submodules
  done
  unset IFS
}

# List all submodules for a git repo, if any.
function _find_git_submodules() {
  if [ -e "$1/../.gitmodules" ]; then
    \grep "\[submodule" "$1/../.gitmodules" | sed "s%\[submodule \"%${1%/.git}/%g" | sed "s/\"]//g"
  fi
}


# Rebuilds index of git repos in $GIT_REPO_DIR.
function _rebuild_git_index() {
  if [ "$1" != "--silent" ]; then echo -e "== Scanning $GIT_REPO_DIR for git repos & submodules..."; fi
  # Get repos from src dir and custom dirs, then sort by basename
  IFS=$'\n'
  for repo in $(echo -e "$(_find_git_repos)\n$(echo $GIT_REPOS | sed "s/:/\\\\n/g")"); do
    echo $(basename $repo | sed "s/ /_/g"):$repo
  done | sort -t ":" -k1,1 | cut -d ":" -f2- >| "$GIT_REPO_DIR/.git_index"
  unset IFS

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
  echo $(sed -e "s/--.*//" "$GIT_REPO_DIR/.git_index" | \grep . | wc -l)
}

# Returns the current $GIT_BINARY branch (returns nothing if not a git repository)
function is_git_dirty {
    [[ $($GIT_BINARY status 2> /dev/null | tail -n1) != "nothing to commit (working directory clean)" ]] && echo "*"
 }
function parse_git_branch {
    $GIT_BINARY branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1/"
}

# If the working directory is clean, update the git repository. Otherwise, show changes.
function _git_index_status_if_dirty() {
  if ! [ `git status --porcelain | wc -l` -eq 0 ]; then
    # Fall back to 'git status' if git status alias isn't configured
    if type $git_status_command 2>&1 | \grep -qv "not found"; then
      eval $git_status_command
    else
      git status
    fi
  fi
}


_git_index_update_all_branches() {
  echo -e "\n## $base_path\n"

  # Save current branch or HEAD revision
  local orig_branch=$(parse_git_branch)
  if [[ "$orig_branch" = "(no branch)" ]]; then
    orig_branch=$(git rev-parse HEAD)
  fi

  # If working directory is dirty, abort
  if [[ -n "$(git status --short 2> /dev/null)" ]]; then
    echo "=== Working directory dirty, nothing to do."
    return
  fi

  local remotes merges branches
  # Get branch configuration from .git/config
  IFS=$'\n'
  for branch in $($GIT_BINARY branch 2> /dev/null | sed -e 's/.\{2\}\(.*\)/\1/'); do
    # Skip '(no branch)'
    if [[ "$branch" = "(no branch)" ]]; then continue; fi

    local remote=$(git config --get branch.$branch.remote)
    local merge=$(git config --get branch.$branch.merge)

    # Ignore branch if remote and merge is not configured
    if [[ -n "$remote" ]] && [[ -n "$merge" ]]; then
      branches=(${branches[@]} "$branch")
      remotes=(${remotes[@]} "$remote")
      # Get branch from merge ref (refs/heads/master => master)
      merges=(${merges[@]} "$(basename $merge)")
    else
      echo "=== Skipping $branch: remote and merge refs are not configured."
    fi
  done
  unset IFS

  # Update all remotes if there are any branches to update
  if [ -n "${branches[*]}" ]; then git fetch --all 2> /dev/null; fi

  local index=0
  # Iterate over branches, and update those that can be fast-forwarded
  for branch in ${branches[@]}; do
    branch_rev="$(git rev-parse $branch)"
    # Local branch can be fast-forwarded if revision is ancestor of remote revision, and not the same.
    # (see http://stackoverflow.com/a/2934062/304706)
    if [[ "$branch_rev" != "$(git rev-parse ${remotes[$index]}/${merges[$index]})" ]] && \
       [[ "$(git merge-base $branch_rev ${remotes[$index]}/${merges[$index]})" = "$branch_rev" ]]; then
      echo "=== Updating $branch branch in $base_path from ${remotes[$index]}/${merges[$index]}..."
      # Checkout branch if we aren't already on it.
      if [[ "$branch" != "$(parse_git_branch)" ]]; then git checkout $branch; fi
      git merge "${remotes[$index]}/${merges[$index]}"
      # Send UI notification of update
      if [ "$NOTIFY" = "true" ]; then
        notify-send "Updated $(basename $base_path) [$branch]" "from ${remotes[$index]}/${merges[$index]}"
      fi
    fi
    let index++
  done

  # Checkout original branch/revision if we aren't already on it.
  if [[ "$orig_branch" != "$(parse_git_branch)" ]]; then git checkout "$orig_branch"; fi
}

# Updates all git repositories with clean working directories.
# Use the following cron configuration:
# */10 * * * * /bin/bash -c '. $HOME/.bashrc && git_index --rebuild && git_index --update-all'
function _git_index_update_all() {
  echo -e "== Safely updating all local branches in $_bld_col$(_git_index_count)$_txt_col repos...\n"
  _git_index_batch_cmd _git_index_update_all_branches
}


# Runs a command for all git repos
function _git_index_batch_cmd() {
  cwd="$PWD"
  if [ -n "$1" ]; then
    echo -e "== Running command for $_bld_col$(_git_index_count)$_txt_col repos...\n"
    unset IFS
    local base_path
    for base_path in $(sed -e "s/--.*//" "$GIT_REPO_DIR/.git_index" | \grep . | sort); do
      builtin cd "$base_path"
      $@
    done
  else
    echo "Please give a command to run for all repos. (It may be useful to write your command as a function or script.)"
  fi
  builtin cd "$cwd"
}


if [ $shell = 'bash' ]; then
	# Bash tab completion function for git_index()
	function _git_index_tab_completion() {
		_check_git_index
		local curw
		IFS=$'\n'
		COMPREPLY=()
		curw=${COMP_WORDS[COMP_CWORD]}

		# If the first part of $curw matches a high-level directory,
		# then match on sub-directories for that project
		local project=$(echo "$curw" | cut -d "/" -f1)
		local base_path=$(\grep "/$project$" "$GIT_REPO_DIR/.git_index" | sed 's/ /\\ /g')

		# If matching project path was found and curr string contains a /, then complete project sub-directories
		if [[ -n "$base_path" && $curw == */* ]]; then
			local search_path=$(echo "$curw" | sed "s:^${project/\\/\\\\\\}::")
			COMPREPLY=($(compgen -d "$base_path$search_path" | \grep -v "/.git" | sed -e "s:$base_path:$project:" -e "s:$:/:" ))

		# If curr string starts with /, tab complete top-level directories in root project dir
		elif [ "${curw:0:1}" = "/" ]; then
		COMPREPLY=($(compgen -d "$GIT_REPO_DIR$curw" | sed -e "s:$GIT_REPO_DIR/::" -e "s:^:/:"))

		# If curr string starts with --, tab complete commands
		elif [ "${curw:0:2}" = "--" ]; then
		local commands="--list\n--rebuild\n--update-all\n--batch-cmd\n--count-by-host"
		COMPREPLY=($(compgen -W '$(echo -e "\n"$commands)' -- $curw))

		# Else, tab complete the entries in .git_index
		else
			COMPREPLY=($(compgen -W '$(sed -e "s:.*/::" -e "s:$:/:" "$GIT_REPO_DIR/.git_index" | sort)' -- $curw))
		fi
		unset IFS
		return 0
	}
else
	function _git_index_tab_completion() {
		typeset -A opt_args
		local state state_descr context line

		_arguments \
			"--rebuild[Rebuild repository index]" \
			"--update-all[Update all indexed repositories]" \
			"--update-all-with-notifications[Update all indexed repositories with notifications]" \
			"--list[List all repositories currently present in the index]" \
			"--count-by-host[Count all repositories per host]" \
			"--batch-cmd+[Run a command on all repositories]:command:->command" \
			"1::Git projects:->projects" \
			&& return 0


		case "$state" in
			projects)
			    # Only check and rebuild index if necessary
			    _check_git_index
			    if [[ $PREFIX == /* ]]; then
				PREFIX=$PREFIX[2,-1]
				_files -X "Files in project directory" -W $GIT_REPO_DIR
			    else
				compadd -X "Git projects" $(sed -e 's:.*/::' -e 's:$:/:' "$GIT_REPO_DIR/.git_index") && return 0
			    fi
			    ;;
			command)
			    local ret=1
			    _call_function ret _command_names
			    return ret
			    ;;
		esac

		return 1
	}
fi
