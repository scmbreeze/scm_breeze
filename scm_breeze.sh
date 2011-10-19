#
# scm_breeze.sh must be sourced, and not executed in a sub-shell.
# e.g "source ~/.scm_breeze/scm_breeze.sh"
# ------------------------------------------------------------
export scmbDir="$(dirname ${BASH_SOURCE:-$0})"

# Load shared functions.
. "$scmbDir/lib/_shared.sh"

# Git
# ------------------------------------------------------------
if [[ -s "$HOME/.git.scmbrc" ]]; then
  # Load config
  . "$HOME/.git.scmbrc"
  . "$scmbDir/lib/git/aliases_and_bindings.sh"
  . "$scmbDir/lib/git/status_shortcuts.sh"
  . "$scmbDir/lib/git/repo_index.sh"
  . "$scmbDir/lib/git/tools.sh"

  if ! type ruby > /dev/null 2>&1; then
    # If Ruby is not installed, fall back to the
    # slower bash/zsh implementation of 'git_status_shortcuts'
    . "$scmbDir/lib/git/fallback/status_shortcuts_shell.sh"
  fi
fi

