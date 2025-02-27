#
# scm_breeze.sh must be sourced, and not executed in a sub-shell.
# e.g "source ~/.scm_breeze/scm_breeze.sh"
# ------------------------------------------------------------
export scmbDir="$(dirname ${BASH_SOURCE:-$0})"

# Load config
[ -s "$HOME/.scmbrc" ] && . "$HOME/.scmbrc"

# Shared functions
source "$scmbDir/lib/scm_breeze.sh"

SCM_BREEZE_DISABLE_ASSETS_MANAGEMENT=${SCM_BREEZE_DISABLE_ASSETS_MANAGEMENT:-""}

if [ "$SCM_BREEZE_DISABLE_ASSETS_MANAGEMENT" != "true" ]; then
  source "$scmbDir/lib/design.sh"
fi

# Git
# ------------------------------------------------------------
if [[ -s "$HOME/.git.scmbrc" ]]; then
  # Load git config
  source "$HOME/.git.scmbrc"
  source "$scmbDir/lib/git/compatibility.sh"
  source "$scmbDir/lib/git/helpers.sh"
  source "$scmbDir/lib/git/aliases.sh"
  source "$scmbDir/lib/git/keybindings.sh"
  source "$scmbDir/lib/git/status_shortcuts.sh"
  source "$scmbDir/lib/git/branch_shortcuts.sh"
  source "$scmbDir/lib/git/grep_shortcuts.sh"
  source "$scmbDir/lib/git/shell_shortcuts.sh"
  if [ "$SCM_BREEZE_DISABLE_ASSETS_MANAGEMENT" != "true" ]; then
    source "$scmbDir/lib/git/repo_index.sh"
  fi
  source "$scmbDir/lib/git/tools.sh"

  if ! type ruby >/dev/null 2>&1; then
    # If Ruby is not installed, fall back to the
    # slower bash/zsh implementation of 'git_status_shortcuts'
    source "$scmbDir/lib/git/fallback/status_shortcuts_shell.sh"
  fi
fi
