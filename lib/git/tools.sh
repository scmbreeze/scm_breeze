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
  files=$@
  git filter-branch --index-filter "git rm -rf --cached --ignore-unmatch $files" HEAD
  # Remove the temporary history git-filter-branch otherwise leaves behind for a long time
  rm -rf .git/refs/original/ && git reflog expire --all &&  git gc --aggressive --prune
}


# Set default remote and merge for a git branch (pull and push)
# Usage: git_set_default_remote(branch = master, remote = origin)
git_set_default_remote() {
  curr_branch=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
  if [ -n "$1" ]; then branch="$1"; else branch="$curr_branch"; fi
  if [ -n "$2" ]; then remote="$2"; else remote="origin"; fi
  echo "branch.$branch.remote: $remote"
  echo "branch.$branch.merge: refs/heads/$branch"
  git config branch.$branch.remote $remote
  git config branch.$branch.merge refs/heads/$branch
}

# Add one git ignore rule, global by default
# Usage: git_ignore [rule] [ignore_file=.gitignore]
git_ignore() {
  if [ -n "$2" ]; then local f="$2"; else local f=".gitignore"; fi
  if [ -n "$1" ] && [ -e $f ] && ! grep -q "$1" $f; then echo "$1" >> $f; fi
}

# Add one git ignore rule, just for your machine
# Usage: git_exclude [rule]
git_exclude() {
  git_ignore "$1" ".git/info/exclude"
}
# Exclude basename of file
git_exclude_basename() {
  git_exclude $(basename "$1")
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
  git bisect start
  git bisect good $1
  git bisect bad
  git bisect run grep -qRE "$2" $search_path
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
  git config -f .git/config --remove-section "submodule.$1"
  git config -f .gitmodules --remove-section "submodule.$1"
  git add .gitmodules
  rm -rf "$1"
  git rm --cached "$1"
}


# Swaps git remotes
# i.e. swap origin <-> username
git_swap_remotes() {
  if [ -z "$2" ]; then
    echo "Usage: $0 remote1 remote2"
    return
  fi
  git remote rename "$1" "$1_temp"
  git remote rename "$2" "$1"
  git remote rename "$1_temp" "$2"
  echo "Swapped $1 <-> $2"
}
# (use git fetch tab completion)
if [ "$shell" = "bash" ]; then
  complete -o default -o nospace -F _git_fetch git_swap_remotes
fi


# Updates cached Travis CI status if repo contains .travis.yml
#
# Creates and excludes TRAVIS_CI_STATUS
# Use with SCM breeze repo index.
# Add the following line to your crontab: (updates every 2 minutes)
# */2 * * * * /bin/bash -c '. /home/YOUR_USERNAME/.bashrc && git_index --rebuild && NOCD=true git_index --batch-cmd git_update_travis_status'
#
git_update_travis_status() {
  if [ -z "$base_path" ]; then local base_path=$(pwd); fi
  if [ -e "$base_path/.travis.yml" ]; then
    if type ruby > /dev/null 2>&1 && type travis > /dev/null 2>&1; then
      # Only use slug from origin
      local repo=$(ruby -e "puts %x[cd $base_path && git remote -v].scan(/origin.*(?:\:|\/)([^\:\/]+\/[^\:\/]+)\.git/m).flatten.uniq")
      local travis_output=$(travis repositories --slugs="$repo")
      local status=""
      case "$travis_output" in
      *Passing*) status="Passing";;
      *Failing*) status="Failing";;
      *Running*) status="Running";;
      esac
      echo "$status" > "$base_path/TRAVIS_CI_STATUS"
      git_ignore "TRAVIS_CI_STATUS" "$base_path/.git/info/exclude"
    fi
  fi
}
