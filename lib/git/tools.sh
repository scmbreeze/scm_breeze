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
  if [ -n "$1" ]; then branch="$1"; else branch="master"; fi
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
    echo "Usage: git_bisect_grep <good_revision> <string>";
    exit 1
  fi
  if [ -n "$3" ]; then search_path="$3"; else search_path="."; fi
  git bisect start
  git bisect good $1
  git bisect bad
  git bisect run grep -qvRE "$2" $search_path
}
