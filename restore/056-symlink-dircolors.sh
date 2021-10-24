#!/bin/bash

set -e

# shellcheck source=./helper_functions.sh
source ./helper_functions.sh

symlink_dotfile ~/dotfiles/dotfiles/.dircolors ~/.dircolors

echo "### .dircolors symlinked"
