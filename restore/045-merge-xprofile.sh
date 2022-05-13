#!/usr/bin/env bash

set -e
echo "Merge lines from the right (my dotfiles) to left (this system file)"
sleep 1
meld ~/.xprofile ~/dotfiles/dotfiles/.xprofile

echo "### .xprofile merged"
