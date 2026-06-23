#!/bin/sh

set -eu

echo "# ------------------------------------"
echo "# START: Install homebrew"
echo "# ------------------------------------"
echo ""

os_name="$(uname -s)"

# macOS では Homebrew インストーラが Xcode Command Line Tools を暗黙に要求する。
# 未導入の場合は GUI プロンプトが出て非対話セットアップ (postCreate 等) で止まるため、
# 事前に xcode-select -p で検出し、未導入なら案内して exit する。
if [ "$os_name" = "Darwin" ]; then
    if ! xcode-select -p >/dev/null 2>&1; then
        echo "ERROR: Xcode Command Line Tools are required on macOS." >&2
        echo "Run the following in an interactive shell, complete the GUI installer, then retry:" >&2
        echo "    xcode-select --install" >&2
        exit 1
    fi
fi

if [ "$os_name" = "Darwin" ]; then
    brew_shellenv_cmd='eval "$(/opt/homebrew/bin/brew shellenv)"'
    brew_binary='/opt/homebrew/bin/brew'
else
    brew_shellenv_cmd='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    brew_binary='/home/linuxbrew/.linuxbrew/bin/brew'
fi

if ! command -v brew >/dev/null 2>&1
then
    echo "Install Homebrew ..."
    # In non-interactive setup (e.g. devcontainer postCreate), fail fast if sudo prompts would block.
    if [ "$os_name" = "Linux" ] && ! sudo -n true >/dev/null 2>&1; then
        echo "ERROR: sudo requires a password. Homebrew install cannot run non-interactively." >&2
        echo "Run setup manually in an interactive shell after fixing sudo policy." >&2
        exit 1
    fi

    NONINTERACTIVE=1 CI=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [ ! -x "$brew_binary" ] && ! command -v brew >/dev/null 2>&1; then
        echo "ERROR: Homebrew installation did not complete." >&2
        exit 1
    fi

    # .zprofile は既に macOS arm64 / Linuxbrew 双方の brew shellenv を分岐実行するため追記不要。
    # 本スクリプト内で brew コマンドを使うために現在シェルにだけ eval する。
    eval "$brew_shellenv_cmd"
    echo ""
else
    echo "Homebrew is already installed."
    echo ""
fi

if ! command -v brew >/dev/null 2>&1; then
    echo "ERROR: brew command not found after setup." >&2
    exit 1
fi

# Homebrew 6+ may require explicit trust for third-party taps in non-interactive runs.
brew tap hashicorp/tap
brew tap terraform-linters/tap
brew trust hashicorp/tap
brew trust terraform-linters/tap

echo "Start brew bundle ..."
brew bundle --file "$HOME/.dotconfig/homebrew/Brewfile_homebrew"
brew bundle --file "$HOME/.dotconfig/homebrew/Brewfile_dev_cli"

# GUI / cask-only Brewfiles are macOS specific.
if [ "$os_name" = "Darwin" ]; then
    brew bundle --file "$HOME/.dotconfig/homebrew/Brewfile_dev_gui"
    brew bundle --file "$HOME/.dotconfig/homebrew/Brewfile_applications"
else
    echo "Skip GUI Brewfiles on $os_name (macOS only)."
fi
