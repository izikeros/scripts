#!/usr/bin/env bash

# author: Krystian Safjan (ksafjan@gmail.com)
# License: MIT

# exit when any command fails
set -e

# initialize
echo "-- initializing local git repo"
git init -b main

# set user
git config user.email "ksafjan@gmail.com"
git config user.name "Krystian Safjan"
echo "-- setting user data"

echo "-- creating github repo: $DIR_NAME"
DIR_NAME=${PWD##*/}

# git pull --set-upstream origin main

gh repo create "$DIR_NAME" --private || echo "not creating repo"

# create .gitignore
echo "-- creating .gitignore"
touch .gitignore
echo ".idea/" >> .gitignore

# add all files, commit and push
echo "-- add all files, commit and push"
git add . && git commit -m "initial commit"

git remote add origin git@github.com:izikeros/$DIR_NAME.git
git branch -M main
git push -u origin main

echo "-- setting upstream"
# git set-upstream is a git alias
#git set-upstream
git branch --set-upstream-to=origin/$(git symbolic-ref --short HEAD)
echo "-- setting authentication with the ssh-keys"


# set ssh authentication
# for macOS use GNU version of sed
[ -d "/usr/local/opt/coreutils/libexec/gnubin" ] && export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"

sed -i 's/url = https:\/\/github.com\//url = github:/' .git/config
sed -i 's/url = git@github.com/url = github/' .git/config
