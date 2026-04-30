# zsh
export ZDOTDIR=$HOME
export ZSHRC_DIR=$ZDOTDIR/.dotconfig/zsh/rc

# homebrew
if [[ "$(uname -s)" == 'Darwin' ]] && [[ "$(uname -m)" == 'arm64' ]] && [[ -x /opt/homebrew/bin/brew ]]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
	eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# git
# global config を ~/.gitconfig.local に固定し、dotfiles 管理下の ~/.gitconfig には環境依存値が書き込まれないようにする
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig.local"

# ghq
# `--global` を付けると include 経由の値を拾えないためスコープ指定を外す（system + global + 現在地 repo を順に探索）
if command -v ghq >/dev/null 2>&1; then
	ghq_root="${GHQ_ROOT:-$(git config --get ghq.root 2>/dev/null || true)}"
	if [ -n "$ghq_root" ]; then
		ghq_root="${ghq_root/#\~/$HOME}"
		mkdir -p "$ghq_root"
		export GHQ_ROOT="$ghq_root"
	fi
fi

# fzf
# --reverse: peco のように候補を上から並べる（デフォルトは下から積む）
export FZF_DEFAULT_OPTS='--reverse'

# history
export HISTSIZE=10000
export SAVEHIST=10000

# bat
export BAT_CONFIG_PATH=$ZDOTDIR/.dotconfig/bat/bat.conf

# volta

# uv
export PATH="$HOME/.local/bin:$PATH"
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
