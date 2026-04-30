#!/bin/sh

set -eu

echo "# ------------------------------------"
echo "# START: Install Node.js via Volta"
echo "# ------------------------------------"
echo ""

# Install volta
# https://docs.volta.sh/guide/getting-started
if command -v volta >/dev/null 2>&1; then
    echo "Volta is already installed."
    echo ""
else
    echo "Installing Volta..."
    curl https://get.volta.sh | bash
    echo ""
fi

export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

volta install node
node -v
