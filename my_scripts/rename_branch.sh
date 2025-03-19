#!/bin/bash

# Ensure a branch name is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <old-branch-name> <new-branch-name>"
    exit 1
fi

OLD_BRANCH=$1
NEW_BRANCH=$2
REMOTE="origin"

# Check if the current branch is the one being renamed
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$CURRENT_BRANCH" = "$OLD_BRANCH" ]; then
    echo "Renaming current branch from $OLD_BRANCH to $NEW_BRANCH"
    git branch -m "$NEW_BRANCH"
else
    echo "Renaming local branch $OLD_BRANCH to $NEW_BRANCH"
    git branch -m "$OLD_BRANCH" "$NEW_BRANCH"
fi

# Push the new branch name to remote
git push "$REMOTE" "$NEW_BRANCH"

# Delete the old branch from remote
git push "$REMOTE" --delete "$OLD_BRANCH"

# Unset and set the upstream branch
git branch --unset-upstream
git branch --set-upstream-to="$REMOTE/$NEW_BRANCH"

echo "Branch renamed successfully!"
echo "If a PR was open for $OLD_BRANCH, you may need to recreate it for $NEW_BRANCH."
