# This loads SCM Breeze into the shell session.
exec_string='[[ -s "$HOME/.scm_breeze/scm_breeze.sh" ]] && . "$HOME/.scm_breeze/scm_breeze.sh"'

# Add line to bashrc and zshrc if not already present.
for rc in bashrc zshrc; do
  if [[ -s "$HOME/.$rc" ]] && ! grep -q "$exec_string" "$HOME/.$rc"; then
    echo "\n$exec_string" >> "$HOME/.$rc"
    echo "== Added SCM Breeze to '~/.$rc'"
  fi
done

# Load SCM Breeze update scripts
. "$HOME/.scm_breeze/lib/scm_breeze.sh"
# Create '~/.*.scmbrc' files from example files
_create_or_patch_scmbrc


echo "== Run 'source ~/.bashrc' or 'source ~/.zshrc' to load SCM Breeze into your current shell."

