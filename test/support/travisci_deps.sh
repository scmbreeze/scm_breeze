#!/usr/bin/env bash
# Installs dependencies for travis-ci environments.

# Install dependencies, which looks to be just bash & zsh.
#
# Darwin has zsh preinstalled already, so only need to install on Ubuntu.
#
# Note: $TRAVIS_OS_NAME will only be set on text boxes with multi-os enabled,
# so use negation test so it will fail gracefully on normal Travis linux setup.
#
# TODO: also perhaps later only on ZSH test box if we split those
if [[ "$TRAVIS_OS_NAME" != "osx" ]]; then
  sudo apt-get install zsh
fi
