git_grep_shortcuts() {
  fail_if_not_git_repo || return 1
  git_clear_vars
  # Run ruby script, store output
  tmp_grep_results="$(git rev-parse --git-dir)/tmp_grep_results_$$"
  git grep -n --color=always "$@" |
    /usr/bin/env ruby "$scmbDir/lib/git/grep_shortcuts.rb" >"$tmp_grep_results"

  # Fetch list of files from last line of script output
  files="$(tail -1 "$tmp_grep_results" | sed 's%@@filelist@@::%%g')"

  # Export numbered env variables for each file
  IFS="|"
  local e=1
  for file in ${=files}; do
    export $git_env_char$e="$file"
    let e++
  done
  IFS=$' \t\n'

  # Print status
  cat "$tmp_grep_results" | sed '$d' | less -SfRMXFi
  rm -f "$tmp_grep_results"
}
