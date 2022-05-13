#!/usr/bin/env bash

# shellcheck source=./helper_functions.sh
source ./helper_functions.sh

mkdir -p ~/Sync
symlink_dotfile "$HOME/Sync/vimwiki" "$HOME/vimwiki"

echo "### vimwiki symlinked from Sync/vimwiki"
