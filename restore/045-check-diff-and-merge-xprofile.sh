#!/usr/bin/env bash

set -e

meld ~/.xprofile ~/dotfiles/dotfiles/.xprofile

echo "### .xprofile merged"
