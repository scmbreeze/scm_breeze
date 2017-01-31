#!/bin/sh
# uninstall by (github: bernardofire)
# Remove line from bashrc and zshrc if present.
for rc in bashrc zshrc; do
  sed -i '/scm_breeze/d' "$HOME/.$rc"
  printf "Removed SCM Breeze from '$HOME/.$rc''%s\n"
done
