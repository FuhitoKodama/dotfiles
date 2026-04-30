#!/bin/sh

set -eu

script_dir=$(cd "$(dirname "$0")" && pwd)

target="VSCode"
source_dir="$HOME/.dotconfig/vscode"
files="settings.json keybindings.json mcp.json"

# Codespaces / Coder は環境変数の有無で分岐するため、-u 下でも空で評価できるよう既定値を入れる
codespaces="${CODESPACES:-}"
coder="${CODER:-}"

if [ "$(uname -s)" = "Darwin" ]; then
    deploy_dir="$HOME/Library/Application Support/Code/User"
    . "$script_dir/util_deploy.sh" "$target" "$deploy_dir" "$source_dir" "$files"
    exit 0
fi

if [ -n "$codespaces" ]; then
    deploy_dir="$HOME/.vscode-remote/data/Machine"
    . "$script_dir/util_deploy.sh" "$target (Codespaces)" "$deploy_dir" "$source_dir" "$files"
fi

if [ -n "$coder" ]; then
    deploy_dir="$HOME/.local/share/code-server/User"
    . "$script_dir/util_deploy.sh" "$target (Coder)" "$deploy_dir" "$source_dir" "$files"
fi

if [ -z "$codespaces" ] && [ -z "$coder" ]; then
    deploy_dir="$HOME/.config/Code/User"
    . "$script_dir/util_deploy.sh" "$target (Linux)" "$deploy_dir" "$source_dir" "$files"
fi
