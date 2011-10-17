#
# scm_breeze.sh must be sourced, and not executed in a sub-shell.
# e.g "source ~/.scm_breeze/scm_breeze.sh"
# ------------------------------------------------------------

export scmbreezeDir="$(dirname ${BASH_SOURCE:-$0})"

# Load config
. "$HOME/.git.scmbrc"

. "$scmbreezeDir/lib/_shared.sh"
. "$scmbreezeDir/lib/git/aliases_and_bindings.sh"
. "$scmbreezeDir/lib/git/status_shortcuts.sh"
. "$scmbreezeDir/lib/git/repo_management.sh"
. "$scmbreezeDir/lib/git/tools.sh"


if ! type ruby > /dev/null 2>&1; then
  # If Ruby is not installed, fall back to the
  # slower bash/zsh implementation of 'git_status_shortcuts'
  . "$scmbreezeDir/lib/git/fallback/status_shortcuts_shell.sh"
fi

