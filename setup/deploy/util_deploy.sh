#!/bin/sh

# このファイルは `source` (`.`) 経由で読み込まれる前提のため、独自の `set -eu` は置かず
# 呼び出し元 (deploy_vscode.sh 等) で有効化された errexit / nounset をそのまま継承する。

# Usage:
# source ./util_deploy.sh <target> <deploy_dir> <source_dir> <files>
# - target     : string, target software name
# - deploy_dir : string, path of directry where to place symbolic links
# - source_dir : string, path of directry which contains files to link
# - files      : array of string, files to link. like 'file1 file2 file3'

target="$1"
deploy_dir="$2"
source_dir="$3"
files="$4"

echo "# ------------------------------------"
echo "# START: Deploy $target"
echo "# ------------------------------------"
echo ""

echo "[INFO] target application: $target"
echo "[INFO] deploy directory  : $deploy_dir"
echo "[INFO] source directory  : $source_dir"
echo "[INFO] files to link     : $files"
echo ""

# Ensure deploy directory exists
mkdir -p "$deploy_dir"

backup_dir="$deploy_dir/.dotbackup/$(date +%Y%m%d-%H%M%S)"

# Link target config files
# shellcheck disable=SC2086 # intentional word splitting on $files
for f in $files
do
    echo "Start to link $f"

    # Skip if already correctly symlinked
    if [ -L "$deploy_dir/$f" ] && [ "$(readlink "$deploy_dir/$f")" = "$source_dir/$f" ]; then
        echo "$f is already linked correctly. Skipping."
        echo ""
        continue
    fi

    if [ -e "$deploy_dir/$f" ] || [ -L "$deploy_dir/$f" ]; then
        echo "$f already exists. Move the old file to backup"
        # Create backup directory lazily
        if [ ! -d "$backup_dir" ]; then
            echo "Create backup directory: $backup_dir"
            mkdir -p "$backup_dir"
        fi
        mv "$deploy_dir/$f" "$backup_dir"
    fi

    ln -sfnv "$source_dir/$f" "$deploy_dir"
    echo ""
done
