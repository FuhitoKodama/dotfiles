#!/bin/sh

set -eu

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

gitconfig_local="$HOME/.gitconfig.local"

echo "# ------------------------------------"
echo "# START: Initialize git identity from GitHub"
echo "# ------------------------------------"
echo ""

if [ ! -f "$gitconfig_local" ]; then
    printf "${RED}ERROR${NC}: %s not found. Run: make deploy-home\n" "$gitconfig_local" >&2
    exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
    printf "${RED}ERROR${NC}: gh CLI is required. Run: make init-brew\n" >&2
    exit 1
fi

if ! gh auth status -h github.com >/dev/null 2>&1; then
    printf "${RED}ERROR${NC}: Not logged in to GitHub. Run: gh auth login\n" >&2
    exit 1
fi

login="$(gh api user -q .login)"
id="$(gh api user -q .id)"
name="$(gh api user -q .name 2>/dev/null || true)"

# 表示名が未設定なら login を使う
if [ -z "$name" ] || [ "$name" = "null" ]; then
    name="$login"
fi

# user scope があれば primary verified email を優先、無ければ noreply アドレスにフォールバック
email=""
if emails_out="$(gh api user/emails --paginate -q '.[] | select(.primary == true and .verified == true) | .email' 2>/dev/null)"; then
    email="$(printf '%s\n' "$emails_out" | head -1)"
fi
if [ -z "$email" ]; then
    email="${id}+${login}@users.noreply.github.com"
    printf "${YELLOW}NOTE${NC}: primary email not accessible (gh user scope missing). Using noreply: %s\n" "$email"
fi

git config --file "$gitconfig_local" user.name "$name"
git config --file "$gitconfig_local" user.email "$email"

printf "${GREEN}✓${NC} Updated %s\n" "$gitconfig_local"
printf "  user.name  = %s\n" "$name"
printf "  user.email = %s\n" "$email"
