#
# scm_breeze.sh must be sourced, and not executed in a sub-shell.
# e.g "source ~/.scm_breeze/scm_breeze.sh"
# ------------------------------------------------------------
export scmbDir="$(dirname ${BASH_SOURCE:-$0})"

# Load config
[ -s "$HOME/.scmbrc" ] && . "$HOME/.scmbrc"

# Shared functions
. "$scmbDir/lib/scm_breeze.sh"
# Design assets management
. "$scmbDir/lib/design.sh"

# Git
# ------------------------------------------------------------
if [[ -s "$HOME/.git.scmbrc" ]]; then
  # Load git config
  . "$HOME/.git.scmbrc"
  . "$scmbDir/lib/git/aliases.sh"
  . "$scmbDir/lib/git/keybindings.sh"
  . "$scmbDir/lib/git/status_shortcuts.sh"
  . "$scmbDir/lib/git/branch_shortcuts.sh"
  . "$scmbDir/lib/git/shell_shortcuts.sh"
  . "$scmbDir/lib/git/repo_index.sh"
  . "$scmbDir/lib/git/tools.sh"

  if ! type ruby > /dev/null 2>&1; then
    # If Ruby is not installed, fall back to the
    # slower bash/zsh implementation of 'git_status_shortcuts'
    . "$scmbDir/lib/git/fallback/status_shortcuts_shell.sh"
  fi
fi

