# -------------------------------------------------------
# Design Assets Management (for Git projects)
# Written by Nathan Broadbent (www.madebynathan.com)
# -------------------------------------------------------
#
# * The `design` function manages the 'design assets' directories for the current project,
#   including folders such as Backgrounds, Logos, Icons, and Samples. The actual directories are
#   created in the root design directory, symlinked into the project, and ignored from source control.
#   This is because we usually don't want to check in design development files such as bitmaps or wav files.
#   It also gives us the option to sync the root design directory via Dropbox.
#
# Examples:
#
#    $ design link        # Requires SCM Breeze - Links existing design directories into each of your projects
#    $ design init        # Creates default directory structure at $root_design_dir/**/ubuntu_config and symlinks into project.
#                           (Images Backgrounds Logos Icons Mockups Screenshots)
#    $ design init --av   # Creates extra directories for audio/video assets
#                           (Images Backgrounds Logos Icons Mockups Screenshots Animations Videos Flash Music Samples)
#    $ design rm          # Removes any design directories for ubuntu_config
#    $ design trim        # Trims empty design directories for ubuntu_config
#


# Add ignore rule to .git/info/exclude if not already present
_design_add_git_exclude(){
  local git_dir="$(cd $1 && cd `git rev-parse --git-dir` && pwd -P)"
  if [ -e "$git_dir/info/exclude" ] && ! $(grep -q "$project_design_dir" "$git_dir/info/exclude"); then
    echo "$project_design_dir" >> "$git_dir/info/exclude"
  fi
}

# Manage design directories for project.
design() {
  local project=`basename $(pwd)`
  local all_project_dirs="$design_base_dirs $design_av_dirs"
  # Ensure design dir contains all subdirectories
  local IFS=$' \t\n'
  # Create root design dirs
  for dir in $design_ext_dirs; do mkdir -p "$root_design_dir/$dir"; done
  # Create project design dirs
  mkdir -p "$root_design_dir/projects"

  if [ -z "$1" ]; then
    echo "design: Manage design directories for project assets that are external to source control."
    echo
    echo "  Examples:"
    echo
    echo "    $ design init        # Creates default directory structure at $root_design_dir/projects/$project and symlinks into project."
    echo "                           ($design_base_dirs)"
    echo "    $ design link        # Links existing design directories into existing repos"
    echo "    $ design init --av   # Adds extra directories for audio/video assets"
    echo "                           ($design_base_dirs $design_av_dirs)"
    echo "    $ design rm          # Removes any design directories for $project"
    echo "    $ design trim        # Trims empty design directories for $project"
    echo
    return 1
  fi

  if [ "$1" = "init" ]; then
    create_dirs="$design_base_dirs"
    if [ "$2" = "--av" ]; then create_dirs+=" $design_av_dirs"; fi
    echo "Creating design directories for '$project': $create_dirs"
    # Create and symlink each directory
    for dir in $create_dirs; do
      mkdir -p "$root_design_dir/projects/$project/$dir"
      if [ ! -e ./$project_design_dir ]; then ln -sf "$root_design_dir/projects/$project" $project_design_dir; fi
    done
    _design_add_git_exclude $PWD

  elif [ "$1" = "link" ]; then
    enable_nullglob
    echo "== Linking existing Design directories into existing repos..."
    for design_project in $root_design_dir/projects/*; do
      proj=$(basename $design_project)
      repo_path=$(grep -m1 "/$proj$" $GIT_REPO_DIR/.git_index)
      if [ -n "$repo_path" ]; then
        if ! [ -e "$repo_path/$project_design_dir" ]; then
          ln -fs "$design_project" "$repo_path/$project_design_dir"
          _design_add_git_exclude "$repo_path"
        fi
        echo "=> $repo_path/$project_design_dir"
      fi
    done
    disable_nullglob

  elif [ "$1" = "rm" ]; then
    echo "Removing all design directories for $project..."
    rm -rf "$root_design_dir/projects/$project" "$project_design_dir"

  elif [ "$1" = "trim" ]; then
    echo "Trimming empty design directories for $project..."
    for dir in $(find $project_design_dir/ -type d -empty); do
      asset=$(basename $dir)
      rm -rf "$project_design_dir/$asset"
    done
    # Remove design dir from project if there's nothing in it.
    if find $project_design_dir/ -type d -empty | grep -q $project_design_dir; then
      rm -rf "$project_design_dir" "$root_design_dir/projects/$project"
    fi

  else
    printf "Invalid command.\n\n"
    design
  fi
}

