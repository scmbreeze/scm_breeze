#########################################################
# Forked from http://github.com/ndbroadbent/scm_breeze  #
#                                                       #
# File Copied and modified from ./install.sh            #
# to be compatible with oh-my-zsh's plugin system       #
#########################################################

#!/bin/bash
#locate the dir where this script is stored
export scmbDir="$( cd -P "$( dirname "$0" )" && pwd )"

# Symlink to ~/.scm_breeze if installing from another path
if [ ! -s "$HOME/.scm_breeze" ] && [ "$scmbDir" != "$HOME/.scm_breeze" ]; then
  ln -fs "$scmbDir" "$HOME/.scm_breeze"

  # Load SCM Breeze update scripts
  source "$scmbDir/lib/scm_breeze.sh"
  # Create '~/.*.scmbrc' files from example files
  _create_or_patch_scmbrc
fi

# This loads SCM Breeze into the shell session.
[ -s "$HOME/.scm_breeze/scm_breeze.sh" ] && source "$HOME/.scm_breeze/scm_breeze.sh"


