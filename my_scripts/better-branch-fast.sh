#!/usr/bin/env bash

# inspiration from FOSDEM talk:
# https://youtu.be/aolI_Rz0ZqY?si=3nbEf8m2sKZDJRQU&t=468
#
# Use git branch --edit-description to set or edit a branch description.
#

# Colors
NO_COLOR='\033[0m'
CYAN='\033[0;36m'
RED='\033[0;31m'

# Print header
printf "%-6s %-7s %-40s %-25s %s\n" "Ahead" "Behind" "Branch" "Last Commit" "Creator"
printf '%.0s-' {1..95}
echo "" # Print dash line

# Get current branch and list of branches
current_branch=$(git rev-parse --abbrev-ref HEAD)
branches=$(git for-each-ref --sort=committerdate refs/heads --format='%(refname:short)' | sort -r)

# Iterate over branches
for branch in $branches; do
	commit_age=$(git log -1 --pretty=format:"%ar" "$branch")
	behind=$(git rev-list --left-only --count "$current_branch"..."$branch")
	ahead=$(git rev-list --right-only --count "$current_branch"..."$branch")
	desc=$(git config branch."$branch".description)
	creator=$(git for-each-ref --format='%(authorname)%09%(refname)' | grep "$branch" | awk -F "\t" '{ printf "%s\n", $(NF-1)}' | head -1)
	branch=$(echo "$branch" | cut -c1-40) # trim the branch name to 40 characters

	# Highlight current branch in green
	if [ "$branch" == "$current_branch" ]; then
		printf "${RED}%-6s %-7s %-40s %-25s %s %s${NO_COLOR}\n" "$ahead" "$behind" "$branch" "$commit_age" "$creator" "$desc"
	else
		# Highlight branches with commit age in months or years in yellow
		if [[ "$commit_age" == *"months ago"* || "$commit_age" == *"years ago"* ]]; then
			printf "${CYAN}%-6s %-7s %-40s %-25s %s %s${NO_COLOR}\n" "$ahead" "$behind" "$branch" "$commit_age" "$creator" "$desc"
		else
			printf "%-6s %-7s %-40s %-25s %s %s\n" "$ahead" "$behind" "$branch" "$commit_age" "$creator" "$desc"
		fi
	fi
done