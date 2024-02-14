#!/usr/bin/env bash
#
# source: https://stackoverflow.com/a/16710084/3247880
# author: https://stackoverflow.com/users/1875092/jsageryd
#
# Use git branch --edit-description to set or edit a branch description.
#

# Shows branches with descriptions
function gb() {
  current=$(git rev-parse --abbrev-ref HEAD)
  branches=$(git for-each-ref --format='%(refname)' refs/heads/ | sed 's|refs/heads/||')
  for branch in $branches; do
    desc=$(git config branch.$branch.description)
    if [ $branch == $current ]; then
      branch="* \033[0;32m$branch\033[0m"
     else
       branch="  $branch"
     fi
     echo -e "$branch \033[0;36m$desc\033[0m"
  done
}