#!/usr/bin/env bash

echo "Merge lines from the right (my dotfiles) to left (this system file)"
sleep 1
meld ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml ~/dotfiles/dotfiles/.config/xfce4/xfwm4/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
