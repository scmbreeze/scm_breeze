function find_in_cwd_or_parent() {
  local slashes=${PWD//[^\/]/}; local directory=$PWD;
  for (( n=${#slashes}; n>0; --n )); do
    test -e "$directory/$1" && echo "$directory/$1" && return 0
    directory="$directory/.."
  done
  return 1
}

function fail_if_not_git_repo() {
  if ! find_in_cwd_or_parent ".git" > /dev/null; then
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
