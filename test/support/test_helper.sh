orig_cwd="$PWD"

# Load SCM Breeze helpers
source "$scmbDir/lib/git/helpers.sh"

# Set up demo git user if not configured
if [ -z "$(git config user.email)" ]; then
  git config user.email "testuser@example.com"
  git config user.name  "Test User"
fi

#
# Test helpers
#-----------------------------------------------------------------------------

# Strip color codes from a string
strip_colors() {
  # Updated with info from: https://superuser.com/a/380778
  perl -pe 's/\x1b\[[0-9;]*[mG]//g'
}

# Print space separated tab completion options
tab_completions(){ echo "${COMPREPLY[@]}"; }

# Silence git commands
silentGitCommands() {
  git() { /usr/bin/env git "$@" > /dev/null 2>&1; }
}

# Cancel silent git commands
verboseGitCommands() {
  unset -f git
}

# Quote the contents of "$@" in single quotes
# Avoid printf '%q' as  'a b'  becomes  a\ b  in both {ba,z}sh
# See also quote_args and double_quote
function token_quote {
  if [[ $shell = bash ]]; then
    # Single quotes are always added
    echo "${@@Q}"
  else  # zsh
    # Single quotes only added when needed
    #shellcheck disable=2154  # zsh
    echo "${(qq)@}"
  fi
}


# Asserts
#-----------------------------------------------------------------------------

_includes() {
  if [ -n "$3" ]; then regex="$3"; else regex=''; fi
  if echo "$1" | grep -q$regex "$2"; then echo 0; else echo 1; fi
}

# assert $1 contains $2
assertIncludes() {
  assertTrue "'$1' should have contained '$2'" $(_includes "$@")
}
# assert $1 does not contain $2
assertNotIncludes() {
  assertFalse "'$1' should not have contained '$2'" $(_includes "$@")
}
