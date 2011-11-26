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
