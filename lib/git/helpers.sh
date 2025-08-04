function fail_if_not_git_repo() {
  if ! $_git_cmd rev-parse --show-toplevel &> /dev/null; then
    echo -e "\033[31mNot a git repository (or any of the parent directories)\033[0m"
    return 1
  fi
  return 0
}

bin_path() {
  if [[ -n ${ZSH_VERSION:-} ]];
    then builtin whence -cp "$1" 2> /dev/null
    else builtin type -P "$1"
  fi
}
