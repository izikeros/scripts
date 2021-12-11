#!/bin/sh

# Usage:
# curl -L https://raw.githubusercontent.com/izikeros/scripts/restore/install.sh | sh

# prerequisites: Zsh & Git
# check Zsh
[ "${SHELL##/*/}" != "zsh" ] && echo 'You might need to change default shell to zsh: `chsh -s /bin/zsh`'
# check Git
[ $(command -v git) ] || echo "You need to install git first"; exit 1

install_dir=$HOME

cd $install_dir
git clone --recursive https://github.com/izikeros/scripts.git

cd $install_dir
git clone --recursive https://github.com/izikeros/dotfiles.git

# run installer
cd $install_dir/dotfiles
sh basic_install.sh
