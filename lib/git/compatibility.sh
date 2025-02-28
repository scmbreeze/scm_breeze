# Earlier versions of SCM Breeze used lowercase variables.
# We now use uppercase variables for exported variables to follow conventions
# and prevent shellcheck warnings. See: https://www.shellcheck.net/wiki/SC2154
# This file converts the old lowercase variables to uppercase if they are not already set.

for setting_var in \
  GIT_ENV_CHAR \
  GS_MAX_CHANGES \
  GA_AUTO_REMOVE \
  GIT_SETUP_ALIASES \
  GIT_SKIP_SHELL_COMPLETION \
  GIT_REPO_DIR \
  GIT_STATUS_COMMAND
do
  lower=$(echo "$setting_var" | tr '[:upper:]' '[:lower:]')
  eval "upper_var=\${$setting_var:-}"
  eval "lower_var=\${$lower:-}"
  if [ -z "$upper_var" ] && [ -n "$lower_var" ]; then
    eval "export $setting_var=\$lower_var"
  fi
done
