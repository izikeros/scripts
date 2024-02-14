#!/usr/bin/env bash

# inspiration from FOSDEM talk:
# https://youtu.be/aolI_Rz0ZqY?si=3nbEf8m2sKZDJRQU&t=468
#
# Use git branch --edit-description to set or edit a branch description.
#

# Print header
printf "%-5s %-5s %-30s %-25s %-35s\n" "Ahead" "Behind" "Branch" "Last Commit" "Description"
printf '%.0s-' {1..80}; echo ""  # Print dash line

# Get current branch and list of branches
current_branch=$(git rev-parse --abbrev-ref HEAD)
branches=$(git for-each-ref --sort=committerdate refs/heads --format='%(refname:short)')
# revert the list of branches to have most recently modified branches in the top 
branches=$(echo "$branches" | tac)

# Iterate over branches
for branch in $branches; do
  #  commit_date=$(git show -s --format=%ci $branch | cut -d' ' -f1) # Extract the date part
  commit_age=$(git log -1 --pretty=format:"%ar" $branch) # Get the commit age
  #  commit_subject=$(git show -s --format=%s $branch) # Get the last commit's description
  ahead=$(git rev-list --left-only --count $current_branch...$branch)
  behind=$(git rev-list --right-only --count $current_branch...$branch)
  desc=$(git config branch.$branch.description)

#  # Highlight current branch in green
#  if [ $branch == $current_branch ]; then
#    branch="* \033[0;32m$branch\033[0m"
#  else
#    branch="  $branch"
#  fi
  # Print branch details
  printf "%-5s %-5s %-30s %-25s %-35s\n" $ahead $behind $branch "$commit_age" "$desc"
done
# reset color
#echo -e "\033[0m"
