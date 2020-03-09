#!/bin/sh
# uninstall by (github: bernardofire)
# Remove line from bashrc and zshrc if present.

sed="sed -i"
if [[ $OSTYPE == "Darwin" ]]; then
  sed="sed -i ''"
fi

if [ -f "$HOME/.bashrc" ]; then
  $sed '/scm_breeze/d' "$HOME/.bashrc" &&
  printf "Removed SCM Breeze from '%s'\n" "$HOME/.bashrc"
fi

if [ -f "${ZDOTDIR:-$HOME}/.zshrc" ]; then
  $sed '/scm_breeze/d' "${ZDOTDIR:-$HOME}/.zshrc" &&
  printf "Removed SCM Breeze from '%s'\n" "${ZDOTDIR:-$HOME}/.zshrc" 
fi
