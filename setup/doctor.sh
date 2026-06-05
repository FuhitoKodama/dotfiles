#!/bin/sh

set -eu

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track overall status
failed_checks=0

check_command() {
    local name="$1"
    local cmd="$2"
    local description="${3:-}"

    if command -v "$cmd" >/dev/null 2>&1; then
        version=$("$cmd" --version 2>&1 | head -1)
        printf "${GREEN}✓${NC} ${name}: ${version}\n"
    else
        printf "${RED}✗${NC} ${name}: NOT INSTALLED\n"
        if [ -n "$description" ]; then
            printf "  ${YELLOW}Hint: ${description}${NC}\n"
        fi
        failed_checks=$((failed_checks + 1))
    fi
}

check_file() {
    local name="$1"
    local filepath="$2"
    local description="${3:-}"

    if [ -f "$filepath" ]; then
        printf "${GREEN}✓${NC} ${name}: ${filepath}\n"
    else
        printf "${RED}✗${NC} ${name}: NOT FOUND at ${filepath}\n"
        if [ -n "$description" ]; then
            printf "  ${YELLOW}Hint: ${description}${NC}\n"
        fi
        failed_checks=$((failed_checks + 1))
    fi
}

check_directory() {
    local name="$1"
    local dirpath="$2"
    local description="${3:-}"

    if [ -d "$dirpath" ]; then
        printf "${GREEN}✓${NC} ${name}: ${dirpath}\n"
    else
        printf "${RED}✗${NC} ${name}: NOT FOUND at ${dirpath}\n"
        if [ -n "$description" ]; then
            printf "  ${YELLOW}Hint: ${description}${NC}\n"
        fi
        failed_checks=$((failed_checks + 1))
    fi
}

check_git_config() {
    local key="$1"
    local hint="$2"

    if git config --get "$key" >/dev/null 2>&1; then
        value=$(git config --get "$key")
        case "$value" in
            YOUR_NAME|YOUR_EMAIL)
                printf "${RED}✗${NC} git config ${key}: ${value} (placeholder)\n"
                if [ -n "$hint" ]; then
                    printf "  ${YELLOW}Hint: ${hint}${NC}\n"
                fi
                failed_checks=$((failed_checks + 1))
                ;;
            *)
                printf "${GREEN}✓${NC} git config ${key}: ${value}\n"
                ;;
        esac
    else
        printf "${RED}✗${NC} git config ${key}: NOT SET\n"
        if [ -n "$hint" ]; then
            printf "  ${YELLOW}Hint: ${hint}${NC}\n"
        fi
        failed_checks=$((failed_checks + 1))
    fi
}

# GIT_CONFIG_GLOBAL は git 2.32 (2021年6月) で導入。未満だと dotfiles の include 逆転方式が無効化され
# ~/.gitconfig (symlink) に credential helper 等が書き込まれて repo が汚染されるため必須チェック。
check_git_version() {
    local required="2.32"

    if ! command -v git >/dev/null 2>&1; then
        return
    fi

    local current
    current=$(git --version 2>/dev/null | awk '{print $3}' | cut -d. -f1,2)
    if [ -z "$current" ]; then
        printf "${RED}✗${NC} git version: could not parse\n"
        failed_checks=$((failed_checks + 1))
        return
    fi

    local req_major req_minor cur_major cur_minor
    req_major=$(echo "$required" | cut -d. -f1)
    req_minor=$(echo "$required" | cut -d. -f2)
    cur_major=$(echo "$current" | cut -d. -f1)
    cur_minor=$(echo "$current" | cut -d. -f2)

    if [ "$cur_major" -gt "$req_major" ] || { [ "$cur_major" -eq "$req_major" ] && [ "$cur_minor" -ge "$req_minor" ]; }; then
        printf "${GREEN}✓${NC} git version >= ${required}: ${current}\n"
    else
        printf "${RED}✗${NC} git version: ${current} (< ${required})\n"
        printf "  ${YELLOW}Hint: GIT_CONFIG_GLOBAL requires git >= ${required}. Run: brew install git${NC}\n"
        failed_checks=$((failed_checks + 1))
    fi
}

check_git_config_global_env() {
    local expected="$HOME/.gitconfig.local"

    if [ "${GIT_CONFIG_GLOBAL:-}" = "$expected" ]; then
        printf "${GREEN}✓${NC} GIT_CONFIG_GLOBAL: ${GIT_CONFIG_GLOBAL}\n"
    else
        printf "${RED}✗${NC} GIT_CONFIG_GLOBAL: ${GIT_CONFIG_GLOBAL:-unset} (expected ${expected})\n"
        printf "  ${YELLOW}Hint: open a new shell so .zshenv takes effect, or run: exec zsh -l${NC}\n"
        failed_checks=$((failed_checks + 1))
    fi
}

echo "==============================================="
echo "  dotfiles setup doctor"
echo "==============================================="
echo ""

# Core tools
echo "${YELLOW}[Core Tools]${NC}"
check_command "Homebrew" "brew" "Run: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
check_command "git" "git" "Run: brew install git"
check_command "zsh" "zsh" "Run: brew install zsh"
echo ""

# Node.js & npm ecosystem
echo "${YELLOW}[Node.js Ecosystem]${NC}"
check_command "volta" "volta" "Run: curl https://get.volta.sh | bash && volta install node"
check_command "node" "node" "Run: volta install node"
check_command "npm" "npm" "Run: volta install node"
echo ""

# Project tools
echo "${YELLOW}[Project Tools]${NC}"
check_command "ghq" "ghq" "Run: brew install ghq"
check_command "fzf" "fzf" "Run: brew install fzf"
echo ""

# Shell customization
echo "${YELLOW}[Shell Customization]${NC}"
check_directory "pure (zsh theme)" "$HOME/.zsh/pure" "Run: make init-custom-pure"
check_file ".zprofile" "$HOME/.zprofile" "Created during init-homebrew"
check_file ".zshrc" "$HOME/.zshrc" "Check if deployed correctly"
echo ""

# VS Code (optional)
echo "${YELLOW}[VS Code (Optional)]${NC}"
vscode_bin=""
for candidate in code code-insiders code-server; do
    if command -v "$candidate" >/dev/null 2>&1; then
        vscode_bin="$candidate"
        break
    fi
done
if [ -n "$vscode_bin" ]; then
    check_command "$vscode_bin" "$vscode_bin" "Run: make deploy-vscode"
    script_dir=$(cd "$(dirname "$0")" && pwd)
    repo_dir=$(cd "$script_dir/.." && pwd)
    check_file "VSCode extensions list" "$repo_dir/.dotconfig/vscode/extensions.txt" "Extensions configuration file"
else
    printf "${YELLOW}~${NC} code / code-insiders / code-server: Not found (optional)\n"
fi
echo ""

# Git configuration
echo "${YELLOW}[Git Configuration]${NC}"
check_git_version
check_git_config_global_env
check_file "~/.gitconfig.local" "$HOME/.gitconfig.local" "Run: make deploy-home (auto-generates from .gitconfig.local.example)"
check_git_config "user.name" "Run: gh auth login && make init-git-identity (writes to ~/.gitconfig.local)"
check_git_config "user.email" "Run: gh auth login && make init-git-identity (writes to ~/.gitconfig.local)"
check_git_config "ghq.root" "Defined in ~/.gitconfig (included by ~/.gitconfig.local)"
# Coder では /workspaces 配下以外がコンテナ停止時に破棄されるため、.zshenv が GHQ_ROOT を /workspaces/ghq に上書きする。
# git config の値（~/ghq）と実効値が乖離するので、最終的に使われる GHQ_ROOT も併せて表示する。
if [ -n "${GHQ_ROOT:-}" ]; then
    printf "${GREEN}✓${NC} GHQ_ROOT (effective): ${GHQ_ROOT}\n"
elif [ "${CODER:-}" = "true" ]; then
    printf "${YELLOW}~${NC} GHQ_ROOT: unset (Coder default /workspaces/ghq will apply on next shell)\n"
fi
echo ""

# Dotfiles deployment
echo "${YELLOW}[Dotfiles Deployment]${NC}"
repo_dir=$(cd "$(dirname "$0")/.." && pwd)
check_file ".dotconfig/vscode/settings.json" "$repo_dir/.dotconfig/vscode/settings.json" "Run: make deploy-vscode"
check_file ".dotconfig/vscode/keybindings.json" "$repo_dir/.dotconfig/vscode/keybindings.json" "Run: make deploy-vscode"
echo ""

# Summary
echo "==============================================="
if [ "$failed_checks" -eq 0 ]; then
    printf "${GREEN}All checks passed! ✓${NC}\n"
    echo "Your dotfiles setup is complete."
else
    printf "${RED}Found ${failed_checks} issue(s).${NC}\n"
    printf "${YELLOW}Review the hints above and run:${NC}\n"
    printf "  ${YELLOW}make init-all${NC} - Initialize core tools\n"
    printf "  ${YELLOW}make deploy-all${NC} - Deploy dotfiles\n"
    printf "  ${YELLOW}make all-in-one${NC} - Full setup\n"
fi
echo "==============================================="

exit "$((failed_checks > 0 ? 1 : 0))"
