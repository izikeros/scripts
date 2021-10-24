#!/bin/bash

# shellcheck source=./helper_functions.sh
source ./helper_functions.sh

symlink_dotfile "$HOME/Dropbox/vimwiki" "$HOME/vimwiki"

echo "### vimwiki symlinked from Dropbox/vimwiki"
