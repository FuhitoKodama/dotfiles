#!/bin/sh

set -eu

echo "# ------------------------------------"
echo "# START: Ensure ghq root directory"
echo "# ------------------------------------"
echo ""

ghq_root="${GHQ_ROOT:-}"
if [ -z "$ghq_root" ]; then
    ghq_root="$(git config --global --get ghq.root 2>/dev/null || true)"
fi

if [ -z "$ghq_root" ]; then
    echo "GHQ_ROOT and git config ghq.root are not set. Skip creating ghq root directory."
    exit 0
fi

case "$ghq_root" in
    "~"|"~/"*) ghq_root="$HOME${ghq_root#\~}" ;;
esac

mkdir -p "$ghq_root"
echo "Ensured ghq root directory: $ghq_root"
