#!/usr/bin/env bash
# Requires bash 4+ for associative arrays; macOS users may need: brew install bash
set -euo pipefail

# inspiration from FOSDEM talk:
# https://youtu.be/aolI_Rz0ZqY?si=3nbEf8m2sKZDJRQU&t=468
#
# Use git branch --edit-description to set or edit a branch description.
#

# Parse arguments
SHOW_PRS=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --with-prs) SHOW_PRS=true; shift ;;
        -h|--help)
            echo "Usage: $(basename "$0") [--with-prs]"
            echo "  --with-prs  Show PR info for each branch (requires gh CLI, slower)"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Colors
NO_COLOR='\033[0m'
CYAN='\033[0;36m'
RED='\033[0;31m'

# Get current branch
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Get all branches
branches=$(git for-each-ref --sort=-committerdate refs/heads --format='%(refname:short)')

# Pre-compute ahead/behind counts in parallel (major speedup with many branches)
ahead_behind_cache=$(mktemp)
trap 'rm -f "$ahead_behind_cache"' EXIT

# Helper script for parallel execution
calc_ahead_behind() {
    local branch="$1"
    local base="$2"
    if [ "$branch" = "$base" ]; then
        echo "$branch|0 0"
    else
        local counts
        counts=$(git rev-list --left-right --count "$base"..."$branch" 2>/dev/null | tr '\t' ' ' || echo "0 0")
        echo "$branch|$counts"
    fi
}
export -f calc_ahead_behind

echo "$branches" | xargs -P4 -I{} bash -c 'calc_ahead_behind "{}" "'"$current_branch"'"' > "$ahead_behind_cache"

# Print header
if $SHOW_PRS; then
    printf "%-6s %-7s %-40s %-25s %-8s %-20s %s\n" "Ahead" "Behind" "Branch" "Last Commit" "Remote" "PR" "Creator"
    printf '%.0s-' {1..130}
else
    printf "%-6s %-7s %-40s %-25s %-8s %s\n" "Ahead" "Behind" "Branch" "Last Commit" "Remote" "Creator"
    printf '%.0s-' {1..110}
fi
echo ""

# Single git query for all branch data (sorted by most recent first)
git for-each-ref --sort=-committerdate refs/heads \
    --format='%(refname:short)|%(committerdate:relative)|%(authorname)|%(upstream:short)' |
while IFS='|' read -r branch commit_age creator upstream; do
    # Skip if empty
    [[ -z "$branch" ]] && continue

    # Get cached ahead/behind counts (lookup from temp file)
    counts=$(grep "^${branch}|" "$ahead_behind_cache" 2>/dev/null | cut -d'|' -f2 || echo "0 0")
    behind=$(echo "$counts" | cut -d' ' -f1)
    ahead=$(echo "$counts" | cut -d' ' -f2)

    # Get branch description
    desc=$(git config "branch.$branch.description" 2>/dev/null || true)

    # Remote tracking status
    if [[ -n "$upstream" ]]; then
        remote_flag="[origin]"
    else
        remote_flag="-"
    fi

    # PR info (optional, slow)
    pr_info="-"
    if $SHOW_PRS && command -v gh &>/dev/null; then
        pr_data=$(gh pr list --head "$branch" --json number,state --jq '.[0] | "#\(.number) \(.state)"' 2>/dev/null || true)
        [[ -n "$pr_data" && "$pr_data" != "null" ]] && pr_info="$pr_data"
    fi

    # Trim branch name for display (preserve original for comparison)
    display_branch="${branch:0:40}"

    # Format output with colors
    if [[ "$branch" == "$current_branch" ]]; then
        color="$RED"
    elif [[ "$commit_age" == *"months ago"* || "$commit_age" == *"years ago"* ]]; then
        color="$CYAN"
    else
        color=""
    fi

    if $SHOW_PRS; then
        if [[ -n "$color" ]]; then
            printf "${color}%-6s %-7s %-40s %-25s %-8s %-20s %s %s${NO_COLOR}\n" \
                "$ahead" "$behind" "$display_branch" "$commit_age" "$remote_flag" "$pr_info" "$creator" "$desc"
        else
            printf "%-6s %-7s %-40s %-25s %-8s %-20s %s %s\n" \
                "$ahead" "$behind" "$display_branch" "$commit_age" "$remote_flag" "$pr_info" "$creator" "$desc"
        fi
    else
        if [[ -n "$color" ]]; then
            printf "${color}%-6s %-7s %-40s %-25s %-8s %s %s${NO_COLOR}\n" \
                "$ahead" "$behind" "$display_branch" "$commit_age" "$remote_flag" "$creator" "$desc"
        else
            printf "%-6s %-7s %-40s %-25s %-8s %s %s\n" \
                "$ahead" "$behind" "$display_branch" "$commit_age" "$remote_flag" "$creator" "$desc"
        fi
    fi
done