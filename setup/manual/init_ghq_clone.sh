#!/bin/sh

set -eu

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# リポジトリ一覧は $HOME/.dotconfig 経由 (deploy 後の symlink) で参照する
list_file="$HOME/.dotconfig/ghq/repositories.txt"

echo "# ------------------------------------"
echo "# START: ghq bulk clone"
echo "# ------------------------------------"
echo ""

if ! command -v ghq >/dev/null 2>&1; then
    printf "${RED}ERROR${NC}: ghq is required. Run: make init-brew\n" >&2
    exit 1
fi

if [ ! -f "$list_file" ]; then
    printf "${RED}ERROR${NC}: %s not found.\n" "$list_file" >&2
    exit 1
fi

# GitHub 系リポジトリを含む場合は認証が無いと clone に失敗する可能性がある
if ! gh auth status -h github.com >/dev/null 2>&1; then
    printf "${YELLOW}WARN${NC}: not logged in to GitHub. Private repos will fail. Run: gh auth login\n" >&2
fi

ok_count=0
failed=""

# while read は末尾 newline が無い最終行を取りこぼすため、`|| [ -n "$line" ]` で補完
while IFS= read -r line || [ -n "$line" ]; do
    # コメントと空行をスキップ
    case "$line" in
        ''|\#*) continue ;;
    esac

    # 行全体の前後空白を除去
    repo=$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    [ -z "$repo" ] && continue

    printf "==> %s\n" "$repo"
    if ghq get -u "$repo"; then
        ok_count=$((ok_count + 1))
    else
        failed="$failed$repo\n"
    fi
    echo ""
done < "$list_file"

echo "# ------------------------------------"
if [ -z "$failed" ]; then
    printf "${GREEN}All ${ok_count} repo(s) synced successfully${NC}\n"
    exit 0
else
    printf "${GREEN}Synced: ${ok_count}${NC}\n"
    printf "${RED}Failed:${NC}\n"
    printf "$failed" | sed 's/^/  - /'
    exit 1
fi
