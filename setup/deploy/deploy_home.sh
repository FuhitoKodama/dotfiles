#!/bin/sh

set -eu

echo "# ------------------------------------"
echo "# START: Deploy home"
echo "# ------------------------------------"
echo ""

# Create base backup directory
if [ ! -d "$HOME/.dotbackup" ]; then
    echo "$HOME/.dotbackup not found. Automatically create it."
    mkdir "$HOME/.dotbackup"
fi

BACKUP_DIR="$HOME/.dotbackup/$(date +%Y%m%d-%H%M%S)"

script_dir=$(cd "$(dirname "$0")" && pwd)
setup_dir=$(dirname "$script_dir")
repository_dir=$(dirname "$setup_dir")

# $HOME に symlink する対象のホワイトリスト。
# .devcontainer / .claude / *.example / .git / .gitignore 等は deploy 対象外のため
# ブラックリスト方式ではなくホワイトリスト方式で明示的に列挙する。
deploy_targets="
.zshenv
.zprofile
.zshrc
.gitconfig
.git-templates
.dotconfig
"

# Link dotfiles to HOME directory
for f in $deploy_targets
do
    if [ ! -e "$repository_dir/$f" ]; then
        echo "WARN: $repository_dir/$f does not exist. Skipping." >&2
        continue
    fi

    # Skip if already correctly symlinked
    if [ -L "$HOME/$f" ] && [ "$(readlink "$HOME/$f")" = "$repository_dir/$f" ]; then
        echo "$f is already linked correctly. Skipping."
        echo ""
        continue
    fi

    echo "Start to link $f"

    if [ -e "$HOME/$f" ] || [ -L "$HOME/$f" ]; then
        echo "$f already exists. Move the old file to backup"
        # Create backup directory lazily
        if [ ! -d "$BACKUP_DIR" ]; then
            echo "Create backup directory: $BACKUP_DIR"
            mkdir "$BACKUP_DIR"
        fi
        mv "$HOME/$f" "$BACKUP_DIR"
    fi

    ln -sfnv "$repository_dir/$f" "$HOME"
    echo ""
done

# ~/.gitconfig.local は GIT_CONFIG_GLOBAL で参照される global config なので、未作成なら example から生成する
if [ ! -e "$HOME/.gitconfig.local" ] && [ -f "$repository_dir/.gitconfig.local.example" ]; then
    echo "Create $HOME/.gitconfig.local from .gitconfig.local.example"
    cp "$repository_dir/.gitconfig.local.example" "$HOME/.gitconfig.local"
    echo "Edit $HOME/.gitconfig.local to set user.name / user.email and credential helper."
    echo ""
fi

# tmux はデフォルトで ~/.tmux.conf を読むため、.dotconfig/tmux/tmux.conf を個別に symlink する
tmux_src="$repository_dir/.dotconfig/tmux/tmux.conf"
tmux_dst="$HOME/.tmux.conf"
if [ -f "$tmux_src" ]; then
    if [ -L "$tmux_dst" ] && [ "$(readlink "$tmux_dst")" = "$tmux_src" ]; then
        echo ".tmux.conf is already linked correctly. Skipping."
        echo ""
    else
        echo "Start to link .tmux.conf"
        if [ -e "$tmux_dst" ] || [ -L "$tmux_dst" ]; then
            echo ".tmux.conf already exists. Move the old file to backup"
            if [ ! -d "$BACKUP_DIR" ]; then
                echo "Create backup directory: $BACKUP_DIR"
                mkdir "$BACKUP_DIR"
            fi
            mv "$tmux_dst" "$BACKUP_DIR"
        fi
        ln -sfnv "$tmux_src" "$tmux_dst"
        echo ""
    fi
fi
