#!/bin/sh

set -eu

echo "# ------------------------------------"
echo "# START: Install VS Code extensions"
echo "# ------------------------------------"
echo ""

script_dir=$(cd "$(dirname "$0")" && pwd)
repo_dir=$(cd "$script_dir/../.." && pwd)
extensions_file="$repo_dir/.dotconfig/vscode/extensions.txt"

if [ ! -f "$extensions_file" ]; then
    echo "Skip: extension list not found: $extensions_file"
    exit 0
fi

if command -v code >/dev/null 2>&1; then
    code_cmd="code"
elif command -v code-insiders >/dev/null 2>&1; then
    code_cmd="code-insiders"
elif command -v code-server >/dev/null 2>&1; then
    code_cmd="code-server"
else
    echo "Skip: VS Code CLI (code / code-insiders / code-server) is not available."
    exit 0
fi

installed_extensions="$($code_cmd --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"

while IFS= read -r raw_line || [ -n "$raw_line" ]; do
    extension=$(printf '%s' "$raw_line" | sed 's/[[:space:]]*#.*$//' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

    if [ -z "$extension" ]; then
        continue
    fi

    if printf '%s\n' "$installed_extensions" | grep -Fqx "$extension"; then
        echo "Skip: $extension is already installed."
        continue
    fi

    echo "Install: $extension"
    "$code_cmd" --install-extension "$extension"
done < "$extensions_file"
