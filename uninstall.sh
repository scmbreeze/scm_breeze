#!/bin/sh
# uninstall by (github: bernardofire)
# Remove line from bashrc and zshrc if present.

sed="sed -i"
if [[ $OSTYPE == "Darwin" ]]; then
  sed="sed -i ''"
fi

for rc in bashrc zshrc; do
  if [ -f "$HOME/.$rc" ]; then
    $sed '/scm_breeze/d' "$HOME/.$rc" &&
      printf "Removed SCM Breeze from %s\n" "$HOME/.$rc"
  fi
done
