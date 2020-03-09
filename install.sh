#!/bin/bash
#locate the dir where this script is stored
export scmbDir="$( cd -P "$( dirname "$0" )" && pwd )"

# Symlink to ~/.scm_breeze if installing from another path
if [ "$scmbDir" != "$HOME/.scm_breeze" ]; then
  ln -fs "$scmbDir" "$HOME/.scm_breeze"
fi

# This loads SCM Breeze into the shell session.
exec_string="[ -s \"$HOME/.scm_breeze/scm_breeze.sh\" ] && source \"$HOME/.scm_breeze/scm_breeze.sh\""

# Add line to bashrc and bash_profile if not already present.
added_to_profile=false
already_present=false
for rc in bashrc bash_profile; do
  if [ -s "$HOME/.$rc" ]; then
    if grep -q "$exec_string" "$HOME/.$rc"; then
      printf "== Already installed in '~/.$rc'\n"
      already_present=true
    else
      printf "\n$exec_string\n" >> "$HOME/.$rc"
      printf "== Added SCM Breeze to '~/.$rc'\n"
      added_to_profile=true
    fi
  fi
done

# Add line to .zshrc if not aleady present.
# When set, the ZDOTDIR environment variable states the directory zshrc is in.
# If not set, HOME environment variable is used as fallback.
if [ -s "${ZDOTDIR:-$HOME}/.zshrc" ]; then
  if grep -q "$exec_string" "${ZDOTDIR:-$HOME}/.zshrc"; then
    printf "== Already installed in '${ZDOTDIR:-$HOME}/.zshrc'\n"
    already_present=true  
  else
    printf "\n$exec_string\n" >> "${ZDOTDIR:-$HOME}/.zshrc"
    printf "== Added SCM Breeze to '${ZDOTDIR:-$HOME}/.zshrc'\n"
    already_present=true
  fi
fi

# Load SCM Breeze update scripts
source "$scmbDir/lib/scm_breeze.sh"
# Create '~/.*.scmbrc' files from example files
_create_or_patch_scmbrc

if [ "$added_to_profile" = true ] || [ "$already_present" = true ]; then
  echo "== SCM Breeze Installed! Run 'source ~/.bashrc || source ~/.bash_profile' or 'source \"${ZDOTDIR:-$HOME}/.zshrc\"'"
  echo "   to load SCM Breeze into your current shell."
else
  echo "== Error:"
  echo "   Found no profile to add SCM Breeze to."
  echo "   Add line to your shell profile and source it to install manually:"
  printf "   $exec_string\n"
fi
