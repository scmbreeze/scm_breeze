# ------------------------------------------------------------------------------
# SCM Breeze - Streamline your SCM workflow.
# Copyright 2011 Nathan Broadbent (http://madebynathan.com). All Rights Reserved.
# Released under the LGPL (GNU Lesser General Public License)
# ------------------------------------------------------------------------------

# Keyboard Bindings
# -----------------------------------------------------------
# 'git_commit_all' and 'git_add_and_commit' give commit message prompts.
# See [here](http://qntm.org/bash#sec1) for info about why I wanted a prompt.

# Cross-shell key bindings
_bind(){
  if [ -n "$1" ]; then
    if [[ $shell == "zsh" ]]; then
      bindkey -s "$1" "$2"
    else # bash
      bind "\"$1\": $2"
    fi
  fi
}

# Keyboard shortcuts for commits
if [[ "$git_keyboard_shortcuts_enabled" = "true" ]]; then
  case "$-" in
  *i*)
      if [ -n "$ZSH_VERSION" ]; then
        RETURN_CHAR="^M"
      else
        RETURN_CHAR="\n"
      fi

      # Uses emacs style keybindings, so vi mode is not supported for now
      if ! set -o | grep -q '^vi .*on$'; then
        if [[ $shell == "zsh" ]]; then
          _bind "$git_commit_all_keys"              " git_commit_all""$RETURN_CHAR"
          _bind "$git_add_and_commit_keys"          " \033[1~ git_add_and_commit ""$RETURN_CHAR"
          _bind "$git_commit_all_with_ci_skip_keys" " \033[1~ GIT_COMMIT_MSG_SUFFIX='[ci skip]' git_commit_all ""$RETURN_CHAR"
        else
          _bind "$git_commit_all_keys"              "\" git_commit_all$RETURN_CHAR\""
          _bind "$git_add_and_commit_keys"          "\"\C-A git_add_and_commit $RETURN_CHAR\""
          _bind "$git_commit_all_with_ci_skip_keys" "\"\C-A GIT_COMMIT_MSG_SUFFIX='[ci skip]' git_commit_all $RETURN_CHAR\""
        fi
      fi

      # Commands are prepended with a space so that they won't be added to history.
      # Make sure this is turned on with:
      # zsh:  setopt histignorespace histignoredups
      # bash: HISTCONTROL=ignorespace:ignoredups
  esac
fi
