# SCM Breeze
### Streamline your SCM workflow.

**Copyright 2011 Nathan Broadbent (http://madebynathan.com). All Rights Reserved.**

-------------------------------------------------------

**SCM Breeze** is a set of shell scripts (for `bash` and `zsh`) that enhance your interaction with SCM tools*,
such as git. It integrates with your shell to offer numbered file shortcuts,
a repository index with tab completion, and a community driven collection of useful SCM functions.

(* Disclaimer: While **git** is currently the only supported SCM, I've kept the project's name open
since it won't be too hard to port these ideas for other SCMs.)

# What does it do?

## File Shortcuts.

This is the main feature of SCM Breeze.
Whenever you view your SCM status, each path is stored in a numbered environment variable.
For example, `git status` has been reimplemented to look like this:

```
# On branch: master  |  [*] => $e*
#
➤ Changes not staged for commit
#
#      modified: [1] README.markdown
#      modified: [2] git.scmbrc.example
#      modified: [3] scm_breeze.sh
#      modified: [4] lib/git/aliases_and_bindings.sh
#      modified: [5] lib/git/status_shortcuts.sh
#      modified: [6] test/lib/git/repo_index_test.sh
#      modified: [7] test/lib/git/repo_management_test.sh
#
```

These numbers (or ranges of numbers) can then be used as parameters for any SCM (or system) command.

For example, if 'ga' was your alias for 'git add', instead of typing:

```bash
ga README.markdown lib/git/ test/lib/
```

You can type this:

```bash
ga 1 4..7
```

You can diff, reset or checkout a file by typing:

```bash
gd 3
grs 4
gco 5
```

And if you want to be really fast, you can use keyboard shortcuts like this:

```
$ 1 4..7 <CTRL>+<x>+<c>


# Becomes...


$  git_add_and_commit 1 4..7
# add '/home/ndbroadbent/src/scm_breeze/README.markdown'
# add '/home/ndbroadbent/src/scm_breeze/lib/git/aliases_and_bindings.sh'
# add '/home/ndbroadbent/src/scm_breeze/lib/git/status_shortcuts.sh'
# add '/home/ndbroadbent/src/scm_breeze/test/lib/git/repo_index_test.sh'
# add '/home/ndbroadbent/src/scm_breeze/test/lib/git/repo_management_test.sh'
#
# On branch: master  |  [*] => $e*
#
➤ Changes to be committed
#
#      modified: [1] README.markdown
#      modified: [2] lib/git/aliases_and_bindings.sh
#      modified: [3] lib/git/status_shortcuts.sh
#      modified: [4] test/lib/git/repo_index_test.sh
#      modified: [5] test/lib/git/repo_management_test.sh
#
Commit Message: |
```


## Repository Index

The second feature is a repository index for all of your projects.
This gives you super-fast switching between your project directories with tab completion.
It can even tab-complete project subdirectories.
It's similar to [autojump](https://github.com/joelthelion/autojump), but it doesn't need to 'learn' anything,
and it can do SCM-specific stuff like:

* Running a command for all of your repos (useful if you ever need to update a lot of remote URLs)
* Auto-updating a repo when you switch to it and it hasn't been updated for at least 5 hours.


## Anything else?

Well, there's also a tiny stub for a 'Misc Git Tools' section.
All it contains at the moment is a command to remove files/folders from git history.

But if you have any awesome SCM scripts lurking in your `.*shrc`, please don't
hesitate to send me a pull request. It would be cool to turn this project into a kind of
[oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh) for SCM users.


## Installation

```bash
git clone git://github.com/ndbroadbent/scm_breeze.git ~/.scm_breeze
cd ~/.scm_breeze
./install.sh
source ~/.bashrc   # or source ~/.zshrc
```

## Configuration

SCM Breeze is configured via automatically installed `*.scmbrc` files.
To change git configuration, edit `~/.git.scmbrc`.

I know that we grow attached to the aliases we use every day, so I've made them completely customizable.
Just change any aliases in `~/.git.scmbrc`, and tab completions will also be updated.
You can also change or remove the keyboard shortcuts.

Each feature is modular, so you are free to ignore the parts you don't want to use.
Just comment out the line in `~/.scm_breeze/scm_breeze.sh`.


## Hope you enjoy!

I look forward to your pull requests!

