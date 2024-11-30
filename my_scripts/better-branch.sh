#!/usr/bin/env bash

# inspiration from FOSDEM talk:
# https://youtu.be/aolI_Rz0ZqY?si=3nbEf8m2sKZDJRQU&t=468
#
# Use git branch --edit-description to set or edit a branch description.
#
# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NO_COLOR='\033[0m'


# Print header
printf "%-5s %-5s %-30s %-25s %s\n" "Ahead" "Behind" "Branch" "Last Commit" "Creator"
printf '%.0s-' {1..80}
echo "" # Print dash line

# Get current branch and list of branches
current_branch=$(git rev-parse --abbrev-ref HEAD)
branches=$(git for-each-ref --sort=committerdate refs/heads --format='%(refname:short)')
# revert the list of branches to have most recently modified branches in the top
#branches=$(echo "$branches" | tac) # this requires coreutils on macos and using gtac
branches=$(echo "$branches" | sort -r)

# Iterate over branches
for branch in $branches; do
  #  commit_date=$(git show -s --format=%ci $branch | cut -d' ' -f1) # Extract the date part
  commit_age=$(git log -1 --pretty=format:"%ar" $branch) # Get the commit age
  #  commit_subject=$(git show -s --format=%s $branch) # Get the last commit's description
  behind=$(git rev-list --left-only --count $current_branch...$branch)
  ahead=$(git rev-list --right-only --count $current_branch...$branch)
  desc=$(git config branch.$branch.description)
  # branch author
  creator=$(git for-each-ref --format='%(authorname)%09%(refname)' | grep $branch | awk -F "\t" '{ printf "%s\n", $(NF-1)}' | head -1)
  # trim the branch name to 30 characters
  branch=$(echo $branch | cut -c1-30)

  # Highlight current branch in green
  if [ $branch == $current_branch ]; then
    printf "${GREEN}%-5s %-5s %-30s %-25s %s %s${NO_COLOR}\n" $ahead $behind $branch "$commit_age" "$creator" "$desc"
  else
    printf "%-5s %-5s %-30s %-25s %s %s\n" $ahead $behind $branch "$commit_age" "$creator" "$desc"
  fi
done
