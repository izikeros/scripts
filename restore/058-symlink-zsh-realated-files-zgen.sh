#!/usr/bin/env bash


# shellcheck source=./helper_functions.sh
source ./helper_functions.sh

symlink_dotfile ./dotfiles/dotfiles/.zshrc ~/.zshrc
symlink_dotfile ./dotfiles/dotfiles/.zsh_aliases ~/.zsh_aliases
symlink_dotfile ./dotfiles/dotfiles/.zsh_functions ~/.zsh_functions
symlink_dotfile ./dotfiles/dotfiles/.zsh_help_functions ~/.zsh_help_functions
symlink_dotfile ./dotfiles/dotfiles/.zgen-setup ~/.zgen-setup

echo "### Zsh-related files symlinked"
