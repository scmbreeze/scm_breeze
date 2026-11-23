#!/bin/bash

export scmbDir="$(cd -P "$(dirname "$0")" && pwd)/../../.."

if [ -n "${ZSH_VERSION:-}" ]; then
  SHUNIT_PARENT=$0
  setopt shwordsplit
fi

source "$scmbDir/lib/scm_breeze.sh"
shell_ls_aliases_enabled=true
export GIT_ENV_CHAR=e
source "$scmbDir/lib/git/shell_shortcuts.sh"

test_ls_shortcuts_preserve_symbolic_links() {
  local fixture_dir
  fixture_dir=$(cd "$SHUNIT_TMPDIR" && pwd -P)
  mkdir "$fixture_dir/listed" "$fixture_dir/targets"
  touch "$fixture_dir/listed/regular" "$fixture_dir/targets/file"
  ln -s ../targets/missing "$fixture_dir/listed/dangling"
  ln -s ../targets/file "$fixture_dir/listed/link with spaces"
  ln -s listed "$fixture_dir/alias"

  LC_ALL=C ls_with_file_shortcuts "$fixture_dir/alias" > "$fixture_dir/output"

  assertEquals "$fixture_dir/listed/dangling" "$e1"
  assertEquals "$fixture_dir/listed/link with spaces" "$e2"
  assertEquals "$fixture_dir/listed/regular" "$e3"
}

source "$scmbDir/test/support/shunit2"
