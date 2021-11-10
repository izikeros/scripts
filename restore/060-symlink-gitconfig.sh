#!/usr/bin/env bash

set -e

# shellcheck source=./helper_functions.sh
source ./helper_functions.sh

symlink_dotfile ~/dotfiles/dotfiles/.gitconfig ~/.gitconfig

echo "### .gitconfig symlinked"
