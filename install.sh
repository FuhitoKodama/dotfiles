#!/bin/sh
# Entry point for Codespaces / Coder dotfiles setup.
# Both platforms look for install.sh (or setup.sh / bootstrap.sh) at the repo root.

set -eu

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Running dotfiles setup from $REPO_DIR"

make -C "$REPO_DIR" all-in-one
