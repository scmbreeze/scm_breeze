# Detect shell
if [ -n "${ZSH_VERSION:-}" ]; then shell="zsh"; else shell="bash"; fi
# Detect whether zsh 'shwordsplit' option is on by default.
if [[ $shell == "zsh" ]]; then zsh_shwordsplit=$((setopt | grep -q shwordsplit) && echo "true"); fi
# Switch on/off shwordsplit for functions that require it.
zsh_compat(){ if [[ $shell == "zsh" && -z $zsh_shwordsplit ]]; then setopt shwordsplit; fi; }
zsh_reset(){  if [[ $shell == "zsh" && -z $zsh_shwordsplit ]]; then unsetopt shwordsplit; fi; }

# Alias wrapper that ignores errors if alias is not defined.
_alias(){ alias "$@" 2> /dev/null; }


# Updates SCM Breeze from GitHub.
update_scm_breeze() {
  currDir=$PWD
  cd "$scmbDir"
  oldHEAD=$(git rev-parse HEAD 2> /dev/null)
  git pull origin master
  # Reload latest version of '_create_or_patch_scmbrc' function
  source "$scmbDir/lib/scm_breeze.sh"
  _create_or_patch_scmbrc
  cd "$currDir"
}

_create_or_patch_scmbrc() {
  # Create or attempt to patch '~/.*.scmbrc' files.
  patchfile=$(mktemp)
  for scm in git; do
    # Create file from example if it doesn't already exist
    if ! [ -e "$HOME/.$scm.scmbrc" ]; then
      cp "$HOME/.scm_breeze/$scm.scmbrc.example" "$HOME/.$scm.scmbrc"
      echo "== '~/.$scm.scmbrc' has been created. Please edit this file to change SCM Breeze settings for '$scm'."
    # If file exists, attempt to update it with any new settings
    else
      # Create diff of example file, substituting example file for user's config.
      git diff $oldHEAD "$scm.scmbrc.example" | sed "s/$scm.scmbrc.example/.$scm.scmbrc/g" > $patchfile
      if [ -s $patchfile ]; then  # If patchfile is not empty
        cd $HOME
        # If the patch cannot be applied cleanly, show the updates and tell user to update file manually.
        if ! patch -f "$HOME/.$scm.scmbrc" $patchfile; then
          echo -e "== \e[0;31mUpdates could not be applied to '\e[1m~/.$scm.scmbrc\e[0;31m'.\e[0m"
          echo -e "== Please look at the following changes and manually update '~/.$scm.scmbrc', if necessary.\n"
          cat "$HOME/.$scm.scmbrc.rej"
        fi
        cd "$scmbDir"
      fi
    fi
  done
}

