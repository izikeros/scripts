#!/bin/bash

# brew
echo "backing up brew leaves"
# todo: try version with tee to avoid double brew leaves
brew leaves > brew_leaves.txt
echo "backing up brew leaves with description"
brew leaves | xargs -n1 brew desc --eval-all > brew_leaves_with_descr.txt
echo "creating Brewbundle"
brew bundle dump

# pipx
echo "backing-up pipx"
pipx list > pipx_list.txt

# Applications
echo "backing-up Applications list"
ls -a ~/Applications > applications.txt


