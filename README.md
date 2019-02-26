<img src="https://user-images.githubusercontent.com/139536/30827652-08e9b684-a265-11e7-95fb-50cbd2fb7c0d.png" width="200" height="200">



# SCM Breeze [![TravisCI](https://secure.travis-ci.org/scmbreeze/scm_breeze.png?branch=master)](http://travis-ci.org/scmbreeze/scm_breeze)

> Streamline your SCM workflow.

**SCM Breeze** is a set of shell scripts (for `bash` and `zsh`) that enhance
your interaction with git. It integrates with your shell to give you numbered
file shortcuts, a repository index with tab completion, and many other useful
features.

- [Installation](#installation)
- [Usage](#usage)
  - [File Shortcuts](#file-shortcuts)
  - [Keyboard bindings](#keyboard-bindings)
  - [Repository Index](#repository-index)
  - [Linking External Project Design Directories](#linking-external-project-design-directories)
- [Configuration](#configuration)
- [Updating](#updating)
- [Uninstalling](#uninstalling)
- [Notes about Tab Completion for Aliases](#notes-about-tab-completion-for-aliases)
- [Contributing](#contributing)


## Installation

```bash
git clone git://github.com/scmbreeze/scm_breeze.git ~/.scm_breeze
~/.scm_breeze/install.sh
source ~/.bashrc   # or source ~/.zshrc
```

The install script creates required default configs and adds the following line
to your `.bashrc` or `.zshrc`:

`[ -s "$HOME/.scm_breeze/scm_breeze.sh" ] && source "$HOME/.scm_breeze/scm_breeze.sh"`

**Note:** SCM Breeze performs much faster if you have ruby installed.

### File Shortcuts

SCM Breeze makes it really easy to work with changed files, and groups of
changed files.  Whenever you view your SCM status, each modified path is stored
in a numbered environment variable.  You can configure the variable prefix,
which is 'e' by default.


#### Git Status Shortcuts:

<div class="centered">
<img src="http://madebynathan.com/images/posts/2011/10/status_with_shortcuts-resized-post.png" width="590" alt="Git Status With Shortcuts" />
</div>
<br/>


#### 'ls' shortcuts:

<div class="centered">
<img src="http://i.imgur.com/72GE1.png" alt="Ls With Shortcuts" />
</div>
<br/>

These numbers (or ranges of numbers) can be used with any SCM or system
command.

For example, if `ga` was your alias for `git add`, instead of typing something
like:

```bash
$ ga assets/git_breeze/config* assets/git_breeze/install.sh
```

You can type this instead:

```bash
$ ga $e2 $e3 $e11
```

But SCM Breeze aliases `ga` to the `git_add_shortcuts` function, which is smart
enough to expand integers and ranges, so all you need to type is:

```bash
$ ga 2 3 11
```

And if you want to add all unstaged changes (files 1 to 10):

```bash
$ ga 1-10
```

(Note that `ga` will also remove deleted files, unlike the standard `git add`
command.  This behaviour can be turned off if you don't like it.)


You can also diff, reset or checkout a file by typing:

```bash
$ gd 3
$ grs 4
$ gco 5
```


You can use these shortcuts with system commands by passing your command
through `exec_scmb_expand_args` (default alias is `ge`):


```bash
$ echo $e4
# => assets/git_breeze/git_breeze.sh
$ ge echo 4
# => assets/git_breeze/git_breeze.sh
$ ge echo 1-3
# expands to echo $e1 $e2 $e3
# => _shared.sh assets/git_breeze/config.example.sh assets/git_breeze/config.sh
```


#### Other shortcuts

SCM Breeze adds a number of aliases to your shell. Use `list_aliases` to view
all the aliases and their corresponding commands.  You can filter aliases by
adding a search string: `list_aliases git log`

There's also a `git_aliases` command, which just shows aliases for `git`
commands. You can also pass in additional filters, e.g. `git_aliases log`.


### Keyboard bindings

Some of my most common git commands are `git add` and `git commit`, so I wanted
these to be as streamlined as possible. One way of speeding up commonly used
commands is by binding them to keyboard shortcuts.

Here are the default key bindings:

* `CTRL`+`x` `c` => `git_add_and_commit` - add given files (if any), then commit staged changes
* `CTRL`+`x` `SPACE` => `git_commit_all` - commit everything


The commit shortcuts use the `git_commit_prompt` function, which gives a simple
prompt like this:

<div class="centered"> <img
src="http://madebynathan.com/images/posts/2011/10/git_commit_all-resized-post.png"
alt="Git Commit All" /> </div> <br/> (When using bash, this commit prompt gives
you access to your bash history via the arrow keys.) <br/>

And if you really want to speed up your workflow, you can type this:

```bash
$ 2 3 <CTRL+x c>
```

This sends the `HOME` key, followed by `git_add_and_commit`:

<div class="centered">
<img src="http://madebynathan.com/images/posts/2011/10/git_add_and_commit_params-resized-post.png" alt="Git Add And Commit" />
</div>
<br/>


### Repository Index

The second feature is a repository index for all of your projects and
submodules.  This gives you super-fast switching between your project
directories, with tab completion, and it can even tab-complete down to project
subdirectories.  This means that you can keep your projects organized in
subfolders, but switch between them as easily as if they were all in one
folder.

It's similar to [autojump](https://github.com/joelthelion/autojump), but it
doesn't need to 'learn' anything, and it can do SCM-specific stuff like:

* Running a command for all of your repos (useful if you ever need to update a
  lot of remote URLs)
* Update all of your repositories via a cron task

The default alias for `git_index` is 'c', which might stand for 'code'

You will first need to configure your repository directory by setting `GIT_REPO_DIR` in `~/.git.sbmrc`.

Then, build the index:

```bash
$ c --rebuild
# => == Scanning /home/ndbroadbent/code for git repos & submodules...
# => ===== Indexed 64 repos in /home/ndbroadbent/code/.git_index
```

Then you'll be able to switch between your projects, or show the list of
indexed repos.

To switch to a project directory, you don't need to type the full project name.
For example, to switch to the `capistrano` project, you could type any of the
following:

```bash
$ c capistrano
$ c cap
$ c istra
```

Or if you wanted to go straight to a subdirectory within `capistrano`:

```bash
$ c cap<TAB>
$ c capistrano/<TAB>
# => bin/   lib/   test/
$ c capistrano/l<TAB>
$ c capistrano/lib/
# => cd ~/code/gems/capistrano/lib
```

Or if you want to go to a subdirectory within the `~/code` directory, prefix
the first argument with a `/`:

```bash
~ $ c /gems
~/code/gems $
```

### Linking External Project Design Directories

When you're creating logos or icons for a project that uses `git`, have you
ever wondered where you should store those `.psd` or `.xcf` files?  Do you
commit all of your raw design files, or does it put you off that any changes to
those files will bloat your repository?

Here were my goals when I set out to find a solution:

* I wanted a design directory for each of my projects
* I didn't want the design directory to be checked in to the git repository
* The design directory needed to be synchronized across all of my machines

The simplest way for me to synchronize files was via my Dropbox account.
However, if you work with a larger team, you could set up a shared design
directory on one of your servers and synchronize it with `rsync`.


#### 1) Create and configure a root design directory

I created my root design directory at `~/Dropbox/Design`.

After you've created your root design directory, edit `~/.scmbrc` and set
`root_design_dir` to the directory you just created.  You can also configure
the design directory that's created in each of your projects (default:
`design_assets`), as well as the subdirectories you would like to use.  The
default base subdirectories are: Images, Backgrounds, Logos, Icons, Mockups,
and Screenshots.

After you have changed these settings, remember to run `source ~/.bashrc` or
`source ~/.zshrc`.


#### 2) Initialize design directories for your projects

To set up the design directories and symlinks, go to a project's directory and
run:

```bash
design init
```

If your root directory is `~/Dropbox/Design`, directories will be created at
`~/Dropbox/Design/projects/my_project/Backgrounds`,
`~/Dropbox/Design/projects/my_project/Icons`, etc.

It will then symlink the project from your root design directory into your
project's design directory, so you end up with:

* `my_project/design_assets` -> `~/Dropbox/Design/projects/my_project`

It also adds this directory to `.git/info/exclude` so that git ignores it.


If you use the git repository index, you can run the following batch command to
set up these directories for all of your git repos at once:

```bash
git_index --batch-cmd design init
```

If you want to remove any empty design directories, run:

```bash
design trim
```

And if you want to remove all of a project's design directories, even if they
contain files:

```bash
design rm
```


#### 3) Link existing design directories into your projects

If you've set up your design directories on one machine, you'll want them to be
synchronized across all of your other development machines.

Just run the following command on your other machines after you've configured
the root design directory:

```bash
design link
```

This uses your git index to figure out where to create the symlinks.  If you
don't use the git index, the same outcome could be achieved by running 'design
init' for each of the projects.


## Configuration

SCM Breeze is configured via automatically installed `~/.*.scmbrc` files.  To
change git configuration, edit `~/.git.scmbrc`.

Each feature is modular, so you are free to ignore the parts you don't want to
use.  Just comment out the relevant line in `~/.scm_breeze/scm_breeze.sh`.

**Note:** After changing any settings, you will need to run `source ~/.bashrc`
(or `source ~/.zshrc`)

I know we grow attached to the aliases we use every day, so I've made the alias
system completely customizable.  You have two options when it comes to aliases:


### 1) Configure and use the provided SCM Breeze aliases

Just tweak the aliases in `~/.git.scmbrc`. You can also change or remove any
keyboard shortcuts.  These aliases also come with tab completion. For example,
you can type `gco <tab>` to tab complete your list of branches.


### 2) Use your own aliases

In your `git.scmbrc` config file, just set the `git_setup_aliases` option to
`no`.  Your existing git aliases will then be used, and you will still be able
to use the numeric shortcuts feature.  SCM Breeze creates a function to wrap
the 'git' command, which expands numeric arguments, and uses `hub` if
available.

A few aliases will still be defined for the central SCM Breeze features, such
as `gs` for the extended `git status`, and `ga` for the `git add` function.

If you already have an alias like `alias gco="git checkout"`, you can now type
`gco 1` to checkout the first file in the output of SCM Breeze's `git status`.

## Custom emojis for username and "staff" group

The `ll` command adds numbered shortcuts to files, but another fun feature is replacing your
username and the "staff" group with custom emojis. You can set these in `~/.user_sym` and `~/.staff_sym`.

<img src="/docs/images/custom_user_and_staff_symbols.jpg" width="400" alt="Custom user and staff emojis">

Set your own emojis by running:

```bash
echo 🍀 > ~/.user_sym
echo 🖥 > ~/.staff_sym
```

I also like using `~/.user_sym` [in my Bash prompt](https://github.com/ndbroadbent/dotfiles/blob/master/bashrc/prompt.sh#L71).


## Notes about Tab Completion for Aliases

### Bash

If you use your own aliases, SCM Breeze will **not** set up bash tab completion
for your aliases.  You will need to set that up yourself.


### Zsh

You just need to set the option: `setopt no_complete_aliases` (oh-my-zsh sets
this by default).  Zsh will then expand aliases like `gb` to `git branch`, and
use the completion for that.


## Updating

Please run `update_scm_breeze` to fetch the latest code. This will update SCM
Breeze from Github, and will create or patch your `~/.*.scmbrc` config files if
any new settings are added.


## Uninstalling

```bash
~/.scm_breeze/uninstall.sh
```

The uninstall script removes the following line from your `.bashrc` or
`.zshrc`:

`[ -s "$HOME/.scm_breeze/scm_breeze.sh" ] && source "$HOME/.scm_breeze/scm_breeze.sh"`


## Contributing

SCM Breeze lives on Github at
[`scmbreeze/scm_breeze`](https://github.com/scmbreeze/scm_breeze)

If you have any awesome SCM scripts lurking in your `.bashrc` or `.zshrc`,
please feel free to send me a pull request.  It would be cool to make this
project into an [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh) for
SCMs.

***Enjoy!***

## Alternative Projects

1. https://github.com/shinriyo/breeze `fish` support
1. https://github.com/mroth/scmpuff static go binary
