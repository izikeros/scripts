#!/usr/bin/env bash

# author: Krystian Safjan (ksafjan@gmail.com)
# License: MIT

# exit when any command fails
set -e

# Get system name
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

# Initialize git repository
echo "-- initializing local git repo"
git init -b main

# Set git user
echo "-- setting user data"
git config user.email "ksafjan@gmail.com"
git config user.name "Krystian Safjan"

# Create GitHub repository
DIR_NAME=${PWD##*/}
echo "-- creating github repo: $DIR_NAME"
gh repo create "$DIR_NAME" --private || echo "not creating repo"

# Create .gitignore file if not exists, append .idea/ to it
echo "-- appending .idea/ to .gitignore"
if [ ! -f .gitignore ]; then
    touch .gitignore
    echo "  -- created .gitignore"
fi
echo ".idea/" >> .gitignore

# Commit code
echo "-- add all files, commit and push"
git add .
git commit -m "initial commit" --quiet

# Push to the remote repository
git remote add origin git@github.com:izikeros/"$DIR_NAME.git" || echo "Remote origin might already exists"
git branch -M main
git push -u origin main --quiet

# Set upstream branch
echo "-- setting upstream"
git branch --set-upstream-to=origin/"$(git symbolic-ref --short HEAD)" main --quiet

# Set SSH authentication
echo "-- setting authentication with the ssh-keys"
SED_CMD=sed

if [ "$machine" == "Mac" ]; then
    # echo "Using gsed (on Darwin)"
    SED_CMD=gsed
fi
# echo $(which $SED_CMD)
$SED_CMD -i 's|url = https://github.com/|url = git@github.com:|' .git/config

echo "Visit: https://github.com/izikeros/$DIR_NAME"
