#!/usr/bin/env bash

# author: Krystian Safjan (ksafjan@gmail.com)
# License: MIT

# exit when any command fails
set -e

# Pre-flight checks
command -v gh >/dev/null || { echo "Error: gh CLI not installed"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "Error: gh not authenticated"; exit 1; }
# Initialize git repository (skip if already a git repo)
if [ -d .git ]; then
    echo "-- already a git repo, skipping git init"
else
    echo "-- initializing local git repo"
    git init -b main
fi

# Set git user
echo "-- setting user data"
git config user.email "ksafjan@gmail.com"
git config user.name "Krystian Safjan"

# Create .gitignore file if not exists, append .idea/ to it (no duplicates)
echo "-- appending .idea/ to .gitignore"
if [ ! -f .gitignore ]; then
    touch .gitignore
    echo "  -- created .gitignore"
fi
grep -qxF '.idea/' .gitignore 2>/dev/null || echo '.idea/' >> .gitignore

# Commit code
echo "-- add all files, commit and push"
git add .
git commit -m "initial commit" --quiet

# Create GitHub repository and push in one command
DIR_NAME=${PWD##*/}
echo "-- creating github repo: $DIR_NAME"
gh repo create "$DIR_NAME" --private --source=. --remote=origin --push

# Final URL
GH_USER=$(gh api user -q .login)
echo "Visit: https://github.com/${GH_USER}/${DIR_NAME}"
