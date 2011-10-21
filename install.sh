#!/bin/sh

#locate the dir where this script is stored
export scmbDir="$(dirname "$0")"
# This loads SCM Breeze into the shell session.
exec_string="[ -s \"$scmbDir/scm_breeze.sh\" ]] && . \"$scmbDir/scm_breeze.sh\""

# Add line to bashrc and zshrc if not already present.
for rc in bashrc zshrc; do
  if [ -s "$HOME/.$rc" ] && ! grep -q "$exec_string" "$HOME/.$rc"; then
    printf "\n$exec_string\n" >> "$HOME/.$rc"
    printf "== Added SCM Breeze to '~/.$rc'\n"
  fi
done

# Load SCM Breeze update scripts
. "$scmbDir/lib/scm_breeze.sh"
# Create '~/.*.scmbrc' files from example files
_create_or_patch_scmbrc


echo "== Run 'source ~/.bashrc' or 'source ~/.zshrc' to load SCM Breeze into your current shell."

