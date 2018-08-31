#!/bin/bash
# uninstall by (github: bernardofire)
# Remove line from bashrc and zshrc if present.

if [[ $OSTYPE == "Darwin" ]]; then 
  for rc in bashrc zshrc; do
    sed -i '' '/scm_breeze/d' "$HOME/.$rc"
    printf "Removed SCM Breeze from %s\n" "$HOME/.$rc"
  endfor
  done
else
if [[ $OSTYPE == "linux-gnu" ]]; then 
  for rc in bashrc zshrc; do
    sed -i '' '/scm_breeze/d' "$HOME/.$rc"
    printf "Removed SCM Breeze from %s\n" "$HOME/.$rc"
  endfor
  done
fi
fi
