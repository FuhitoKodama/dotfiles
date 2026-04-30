# ------------------------------------------------------------------------
# Reset 
# ------------------------------------------------------------------------

# Reset to default keybind
bindkey -d

# ------------------------------------------------------------------------
# macOS basis
# ------------------------------------------------------------------------

# Enable Emacs keybind
bindkey -e

# Enable fn + delete key
bindkey "^[[3~" delete-char

# ------------------------------------------------------------------------
# History
# ------------------------------------------------------------------------

# fzf で履歴を選択。--no-sort で履歴順を保持、--query で現在のバッファを初期クエリに
# https://qiita.com/shepabashi/items/f2bc2be37a31df49bca5
function fzf-history-selection() {
  BUFFER=$(history -n 1 | awk '!seen[$0]++ { lines[++n]=$0 } END { for (i=n; i>=1; i--) print lines[i] }' | fzf --no-sort --query "$LBUFFER")
    CURSOR=$#BUFFER
    zle reset-prompt
}
zle -N fzf-history-selection
bindkey '^R' fzf-history-selection

# ------------------------------------------------------------------------
# cdr
# ------------------------------------------------------------------------

# fzf で cdr から移動先を選択
# https://qiita.com/sukebeeeeei/items/9b815e56a173a281f42f
if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
    autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
    add-zsh-hook chpwd chpwd_recent_dirs
    zstyle ':completion:*' recent-dirs-insert both
    zstyle ':chpwd:*' recent-dirs-default true
    zstyle ':chpwd:*' recent-dirs-max 1000
    zstyle ':chpwd:*' recent-dirs-file "$HOME/.cache/chpwd-recent-dirs"
fi
function fzf-get-destination-from-cdr() {
  cdr -l | \
  sed -e 's/^[[:digit:]]*[[:blank:]]*//' | \
  fzf --no-sort --query "$LBUFFER"
}
function fzf-cdr() {
  local destination="$(fzf-get-destination-from-cdr)"
  if [ -n "$destination" ]; then
    BUFFER="cd $destination"
    zle accept-line
  else
    zle reset-prompt
  fi
}
zle -N fzf-cdr
bindkey '^U' fzf-cdr

# ------------------------------------------------------------------------
# ghq
# ------------------------------------------------------------------------

# fzf で ghq 管理リポジトリを選択して cd
function fzf-ghq () {
  local selected_dir=$(ghq list -p | fzf --query "$LBUFFER")
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N fzf-ghq
bindkey '^G^G' fzf-ghq

# fzf で選択して、vscode で開く
function fzf-ghq-vscode () {
  local selected_dir=$(ghq list -p | fzf --query "$LBUFFER")
  if [ -n "$selected_dir" ]; then
    BUFFER="code ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N fzf-ghq-vscode
bindkey '^G^F' fzf-ghq-vscode


# ------------------------------------------------------------------------
# 自分のGitHub Repositoryをクエリして開く
# ------------------------------------------------------------------------

# 自分 + 所属 org を --owner に指定して、入力のたびに gh search repos に投げる。
# fzf のローカル絞り込みは --disabled で無効化し、検索は GitHub 側に任せる。
# 選ばれた owner/name を stdout に出す。
# 戻り値: 0=選択, 2=未認証, その他=fzf の exit code (キャンセル等)
_fzf-gh-search-select() {
  local prompt="${1:-gh search}"
  local login=$(gh api user --jq .login 2>/dev/null)
  if [ -z "$login" ]; then
    return 2
  fi
  local owner_flags="--owner=$login"
  local org
  for org in ${(f)"$(gh api user/orgs --jq '.[].login' 2>/dev/null)"}; do
    owner_flags+=" --owner=$org"
  done
  local gh_search="gh search repos --limit 100 --json fullName --jq '.[].fullName' $owner_flags"
  eval "$gh_search" 2>/dev/null | fzf \
    --disabled \
    --prompt="${prompt}> " \
    --bind="change:reload:sleep 0.2; $gh_search {q} 2>/dev/null || true"
}

function open-my-repos() {
  if ! type gh >/dev/null 2>&1; then
    zle -M "gh not found: install GitHub CLI (brew install gh)"
    return
  fi
  local selected_repo
  selected_repo=$(_fzf-gh-search-select 'gh view')
  if [ $? -eq 2 ]; then
    zle -M "gh: not authenticated (run: gh auth login)"
    return
  fi
  if [ -n "$selected_repo" ]; then
    BUFFER="gh repo view --web ${selected_repo}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N open-my-repos
bindkey '^G^H' open-my-repos

# gh search で選んだリポジトリを ghq get する
function fzf-ghq-get() {
  if ! type gh >/dev/null 2>&1; then
    zle -M "gh not found: install GitHub CLI (brew install gh)"
    return
  fi
  if ! type ghq >/dev/null 2>&1; then
    zle -M "ghq not found: install ghq (brew install ghq)"
    return
  fi
  local selected_repo
  selected_repo=$(_fzf-gh-search-select 'ghq get')
  if [ $? -eq 2 ]; then
    zle -M "gh: not authenticated (run: gh auth login)"
    return
  fi
  if [ -n "$selected_repo" ]; then
    BUFFER="ghq get ${selected_repo}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N fzf-ghq-get
bindkey '^G^P' fzf-ghq-get
