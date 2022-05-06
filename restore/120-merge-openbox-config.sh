#!/usr/bin/env bash

# shellcheck source=./helper_functions.sh
source ./helper_functions.sh
# symlink_dotfile "$HOME/dotfiles/dotfiles/$PTH/config" "$HOME/$PTH/config"

symlink_dotfile ~/dotfiles/dotfiles/.config/openbox/rc.xml ~/.config/openbox/rc.xml
symlink_dotfile ~/dotfiles/dotfiles/.config/openbox/autostart ~/.config/openbox/autostart
symlink_dotfile ~/dotfiles/dotfiles/.config/openbox/environment ~/.config/openbox/environment
