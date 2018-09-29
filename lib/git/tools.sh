# -------------------------------------------------------
# SCM Breeze - Streamline your SCM workflow.
# Copyright 2011 Nathan Broadbent (http://madebynathan.com). All Rights Reserved.
# Released under the LGPL (GNU Lesser General Public License)
# -------------------------------------------------------

# -----------------------------------------------------------------
# Git Tools
# - Please feel free to add your own git scripts, and send me a pull request
#   at https://github.com/ndbroadbent/scm_breeze
# -----------------------------------------------------------------


# Remove files/folders from git history
# -------------------------------------------------------------------
# To use it, cd to your repository's root and then run the function
# with a list of paths you want to delete. e.g. git_remove_history path1 path2
# Original Author: David Underhill
git_remove_history() {
  # Make sure we're at the root of a git repo
  if [ ! -d .git ]; then
      echo "Error: must run this script from the root of a git repository"
      return
  fi
  # Remove all paths passed as arguments from the history of the repo
  local files
  files=("$@")
  $_git_cmd filter-branch --index-filter "$_git_cmd rm -rf --cached --ignore-unmatch ${files[*]}" HEAD
  # Remove the temporary history git-filter-branch otherwise leaves behind for a long time
  rm -rf .git/refs/original/ && $_git_cmd reflog expire --all &&  $_git_cmd gc --aggressive --prune
}


# Set default remote and merge for a git branch (pull and push)
# Usage: git_set_default_remote(branch = master, remote = origin)
git_set_default_remote() {
  curr_branch=$($_git_cmd branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
  if [ -n "$1" ]; then branch="$1"; else branch="$curr_branch"; fi
  if [ -n "$2" ]; then remote="$2"; else remote="origin"; fi
  echo "branch.$branch.remote: $remote"
  echo "branch.$branch.merge: refs/heads/$branch"
  $_git_cmd config branch.$branch.remote $remote
  $_git_cmd config branch.$branch.merge refs/heads/$branch
}

# Add one git ignore rule, global by default
# Usage: git_ignore [rule] [ignore_file=.gitignore]
__git_ignore() {
  if [ -n "$2" ]; then local f="$2"; else local f=".gitignore"; fi
  if [ -n "$1" ] && ! ([ -e $f ] && grep -q "$1" $f); then echo "$1" >> $f; fi
}
# Always expand args
git_ignore() {
  exec_scmb_expand_args __git_ignore "$@"
}

# Add one git ignore rule, just for your machine
# Usage: git_exclude [rule]
git_exclude() {
  git_ignore "$1" ".git/info/exclude"
}

# Exclude basename of file
__git_exclude_basename() {
  __git_ignore "$(basename "$1")" ".git/info/exclude"
}
git_exclude_basename() {
  exec_scmb_expand_args __git_exclude_basename "$@"
}



# Use git bisect to find where text was removed from a file.
#
# Example:
#
# - Locate the commit where the text "strawberry" was removed from the file 'FRUITS'.
#   - The text was not present in 992048f
#
#  git_bisect_grep 992048f "strawberry" FRUITS
#
git_bisect_grep() {
  if [ -z "$2" ]; then
    echo "Usage: $0 <good_revision> <string>";
    return
  fi
  if [ -n "$3" ]; then search_path="$3"; else search_path="."; fi
  $_git_cmd bisect start
  $_git_cmd bisect good $1
  $_git_cmd bisect bad
  $_git_cmd bisect run grep -qRE "$2" $search_path
}


# Removes a git submodule
# (from http://stackoverflow.com/a/7646931/304706)
# Deletes the sections from .gitmodules, .git/config,
# and runs git rm --cached path/to/submodule.
git_submodule_rm() {
  if [ -z "$1" ]; then
    echo "Usage: $0 path/to/submodule (no trailing slash)"
    return
  fi
  $_git_cmd config -f .git/config --remove-section "submodule.$1"
  $_git_cmd config -f .gitmodules --remove-section "submodule.$1"
  $_git_cmd add .gitmodules
  rm -rf "$1"
  $_git_cmd rm --cached "$1"
}


# Swaps git remotes
# i.e. swap origin <-> username
git_swap_remotes() {
  if [ -z "$2" ]; then
    echo "Usage: git_swap_remotes remote1 remote2"
    return
  fi
  $_git_cmd remote rename "$1" "$1_temp"
  $_git_cmd remote rename "$2" "$1"
  $_git_cmd remote rename "$1_temp" "$2"
  echo "Swapped $1 <-> $2"
}
# (use git fetch tab completion)
if [ "$shell" = "bash" ]; then
  complete -o default -o nospace -F _git_fetch git_swap_remotes
fi


# Delete a git branch from local, cached remote and remote server
git_branch_delete_all() {
  if [ -z "$1" ]; then
    echo "Usage: git_branch_delete_all branch (-f forces deletion of unmerged branches.)"
    return
  fi
  local opt="-d"
  if [ "$2" = '-f' ] || [ "$2" = '--force' ]; then opt="-D"; fi

  $_git_cmd branch $opt $1
  $_git_cmd branch $opt -r origin/$1
  $_git_cmd push origin :$1
}

commit_docs() {
  git commit -m "Update README / Documentation [ci skip]"
}
