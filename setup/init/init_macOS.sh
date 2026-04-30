#!/bin/sh

set -eu

if [ "$(uname -s)" != "Darwin" ]; then
    echo "Skip init_macOS.sh on non-macOS environment."
    exit 0
fi

# Trackpad speed
defaults write -g com.apple.mouse.scaling 2.5

# Dock size
current_tilesize=$(defaults read com.apple.dock tilesize 2>/dev/null)
if [ "$current_tilesize" != "37" ]; then
    defaults write com.apple.dock tilesize -integer 37
    killall Dock
fi
