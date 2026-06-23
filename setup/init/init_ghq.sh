#!/bin/sh

set -eu

echo "# ------------------------------------"
echo "# START: Ensure ghq root directory"
echo "# ------------------------------------"
echo ""

ghq_root="${GHQ_ROOT:-}"
git_global_target="${GIT_CONFIG_GLOBAL:-$HOME/.gitconfig}"
# Coder: /workspaces 配下以外はコンテナ停止時に破棄されるため ghq の実体を /workspaces/ghq に逃がす
# （明示的な GHQ_ROOT が優先、未設定時のみ Coder のデフォルトを適用）
if [ -z "$ghq_root" ] && [ "${CODER:-}" = "true" ]; then
    ghq_root="/workspaces/ghq"

    # Persist root so subsequent non-login shells also resolve ghq under /workspaces.
    git config --file "$git_global_target" ghq.root "$ghq_root"
fi
if [ -z "$ghq_root" ]; then
    # Do not use --global; include chains (e.g. ~/.gitconfig.local -> ~/.gitconfig) must be respected.
    ghq_root="$(git config --get ghq.root 2>/dev/null || true)"
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
