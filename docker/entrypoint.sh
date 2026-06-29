#!/bin/bash
set -e

if [ ! -f "$HOME/.scm_breeze_installed" ]; then
  if [ -d /workspace ] && [ -f /workspace/install.sh ]; then
    bash /workspace/install.sh >/dev/null || true
    touch "$HOME/.scm_breeze_installed"
  else
    echo "warning: /workspace/install.sh not found — did you bind-mount the repo to /workspace?" >&2
  fi
fi

SANDBOX_REPO="$HOME/sandbox-repo"
if [ ! -d "$SANDBOX_REPO/.git" ]; then
  mkdir -p "$SANDBOX_REPO"
  (
    cd "$SANDBOX_REPO"
    git init -q
    echo "hello" > README.md
    git add README.md
    git commit -q -m "initial"
    echo "change" >> README.md
    echo "untracked" > new.txt
  )
fi

cat <<EOF
scm_breeze sandbox — git + scm_breeze only, no other shell config.
  /workspace        bind-mounted repo (host edits are live)
  ~/sandbox-repo    throwaway git repo with staged/unstaged/untracked changes
  zsh               run \`zsh\` to switch shells
  tests             cd /workspace && ./run_tests.sh
EOF

exec "$@"
