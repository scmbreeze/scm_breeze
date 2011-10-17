# This loads SCM Breeze into the shell session.
exec_string='[[ -s "$HOME/.scm_breeze/scm_breeze.sh" ]] && . "$HOME/.scm_breeze/scm_breeze.sh"'

# Add line to bashrc and zshrc if not already present.
for rc in bashrc zshrc; do
  if [[ -s "$HOME/.$rc" ]] && ! grep -q "$exec_string" "$HOME/.$rc"; then
    echo -e "\n$exec_string" >> "$HOME/.$rc"
    echo "== Added SCM Breeze to '~/.$rc'"
  fi
done


# Set up ~/*.scmbrc files
# ---------------------------------------------------------------------------------------------
# Git
if ! [[ -s "$HOME/.git.scmbrc" ]]; then
  cp "$HOME/.scm_breeze/git.scmbrc.example" "$HOME/.git.scmbrc"
  echo "== 'git.scmbrc.example' has been copied to '~/.git.scmbrc'.
   Please edit this file to change SCM Breeze settings, Git aliases, and Git keyboard bindings."
fi

