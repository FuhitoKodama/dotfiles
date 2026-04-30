# ------------------------------------------------------------------------
# xxenv
# ------------------------------------------------------------------------

# pyenv
if [ -d "$HOME/.pyenv" ]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv init - --no-rehash)"
fi

# go
if command -v go >/dev/null 2>&1; then
    export GOPATH=$HOME/.go
    export PATH=$GOPATH/bin:$PATH
fi
