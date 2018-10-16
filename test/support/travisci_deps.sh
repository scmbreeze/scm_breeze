#!/usr/bin/env bash
# Installs dependencies for travis-ci environments.

# Install dependencies, which looks to be just bash & zsh.
#
# Darwin has zsh preinstalled already, so only need to install on Ubuntu.
#
# Note: $TRAVIS_OS_NAME will only be set on text boxes with multi-os enabled,
# so use negation test so it will fail gracefully on normal Travis linux setup.
if [[ "$TRAVIS_OS_NAME" != "osx" ]]; then

  # okay, so we know we're probably on a linux box (or at least not an osx box)
  # at this point. do we need to install zsh? let's say the default case is no:
  needs_zsh=false

  # check if zsh is listed in the TEST_SHELLS environment variable, set by
  # our travis-ci build matrix.
  if [[ $TEST_SHELLS =~ zsh ]]; then needs_zsh=true; fi

  # if there is NO $TEST_SHELLS env variable persent (which should never happen,
  # but maybe someone has been monkeying with the .travis.yml), run_tests.sh is
  # going to fall back onto the default of testing everything, so we need zsh.
  if [[ -z "$TEST_SHELLS" ]]; then needs_zsh=true; fi

  # finally, we install zsh if needed!
  if $needs_zsh; then
    sudo apt-get update
    sudo apt-get install zsh
  else
    echo "No deps required."
  fi
fi
