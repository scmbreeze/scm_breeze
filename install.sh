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
for scm in git; do
  if ! [[ -s "$HOME/.$scm.scmbrc" ]]; then
    cp "$HOME/.scm_breeze/$scm.scmbrc.example" "$HOME/.$scm.scmbrc"
    echo "== '~/.$scm.scmbrc' has been created. Please edit this file to change '$scm' settings."
  fi
done

