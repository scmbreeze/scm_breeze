#
# Get directory of this file (for bash and zsh).
# git_breeze.sh must not be run directly.
# It must be sourced, e.g "source ~/.git_breeze/git_breeze.sh"
# ------------------------------------------------------------

export gitbreezeDir="$(dirname ${BASH_SOURCE:-$0})"

# Load config
. "$HOME/.git.scmbrc"

. "$gitbreezeDir/lib/_shared.sh"
. "$gitbreezeDir/lib/git/aliases_and_bindings.sh"
. "$gitbreezeDir/lib/git/status_shortcuts.sh"
. "$gitbreezeDir/lib/git/repo_management.sh"
. "$gitbreezeDir/lib/git/tools.sh"


if ! type ruby > /dev/null 2>&1; then
  # If Ruby is not installed, fall back to the
  # slower bash/zsh implementation of 'git_status_shortcuts'
  . "$gitbreezeDir/lib/git/fallback/status_shortcuts_shell.sh"
fi

