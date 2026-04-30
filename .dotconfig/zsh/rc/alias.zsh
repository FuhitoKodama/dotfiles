# ------------------------------------------------------------------------
# Git
# ------------------------------------------------------------------------

alias gs='git status'
alias gc='git commit'
alias gcm='git commit -m'
alias gcam='git commit -am '
alias gga='git graphall'
alias gaa='git add -A'
alias gd='git diff'
alias gf='git fetch -p --all'

# ------------------------------------------------------------------------
# AWS
# ------------------------------------------------------------------------

# AWS_* 環境変数をすべて unset する
# `unset $(...)` は zsh で展開結果が空のときエラーになるため関数でガードする
raws() {
	# shellcheck disable=SC2046  # intentional word splitting to pass multiple names to unset
	local vars
	vars=$(env | grep -E '^AWS_' | cut -d= -f1)
	[ -n "$vars" ] && unset $(echo "$vars")
}

# ------------------------------------------------------------------------
# Terraform
# ------------------------------------------------------------------------

alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfaauto='terraform apply --auto-approve'
alias tff='terraform fmt --recursive'

# ------------------------------------------------------------------------
# zsh
# ------------------------------------------------------------------------

# 起動速度測定
alias timezsh='time zsh -i -c exit'

# .zshxx再読み込み
alias reloadzsh="source $ZDOTDIR/.zshenv && source $ZDOTDIR/.zprofile && source $ZDOTDIR/.zshrc"

# ------------------------------------------------------------------------
# tree
# ------------------------------------------------------------------------

# .git を無視
alias tg='tree -a -I ".git"'


# ------------------------------------------------------------------------
# ls
# ------------------------------------------------------------------------

# BSD(macOS) は -G でカラー、GNU(Linux) は --color=auto でカラー。-G の意味が逆なので分岐する
if [[ "$OSTYPE" == darwin* ]]; then
	alias ls='ls -G'
	alias ll='ls -lhG'
	alias la='ls -lahG'
else
	alias ls='ls --color=auto'
	alias ll='ls -lh --color=auto'
	alias la='ls -lah --color=auto'
fi

# ------------------------------------------------------------------------
# cd
# ------------------------------------------------------------------------

alias ..='cd ..'
alias ..2='cd ../..'
alias ..3='cd ../../..'

# ------------------------------------------------------------------------
# Edit dotfiles
# ------------------------------------------------------------------------

alias vdot='vi $HOME/.dotconfig'

# ------------------------------------------------------------------------
# VS Code CLI fallback (for coder/code-server environments)
# ------------------------------------------------------------------------

if ! command -v code >/dev/null 2>&1 && command -v code-server >/dev/null 2>&1; then
	alias code='code-server'
fi

# ------------------------------------------------------------------------
# other
# ------------------------------------------------------------------------

