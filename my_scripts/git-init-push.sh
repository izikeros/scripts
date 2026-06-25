#!/usr/bin/env bash
#
# git-init-push.sh - Initialize git repo, add .gitignore, create GitHub remote, and push
#
# Usage: git-init-push.sh [--public]
#   --public  Create a public repository (default is private)
#
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Expected GitHub username (safety check)
EXPECTED_USER="izikeros"

# Parse arguments
VISIBILITY="private"
if [[ "${1:-}" == "--public" ]]; then
    VISIBILITY="public"
fi

echo -e "${YELLOW}=== Git Init & Push Script ===${NC}"

# Safety check: Verify correct GitHub account is active
echo -e "\n${YELLOW}Checking GitHub authentication...${NC}"
CURRENT_USER=$(gh api user --jq '.login' 2>/dev/null) || {
    echo -e "${RED}ERROR: Failed to get GitHub user. Is 'gh' authenticated?${NC}"
    echo "Run: gh auth login"
    exit 1
}

if [[ "$CURRENT_USER" != "$EXPECTED_USER" ]]; then
    echo -e "${RED}ERROR: Wrong GitHub account active!${NC}"
    echo -e "  Current user: ${RED}$CURRENT_USER${NC}"
    echo -e "  Expected:     ${GREEN}$EXPECTED_USER${NC}"
    echo ""
    echo "To switch accounts, run:"
    echo "  gh auth switch -u $EXPECTED_USER"
    exit 1
fi

echo -e "${GREEN}Authenticated as: $CURRENT_USER${NC}"

# Get repository name from current directory
REPO_NAME=$(basename "$PWD")
echo -e "\nRepository name: ${GREEN}$REPO_NAME${NC}"
echo -e "Visibility: ${GREEN}$VISIBILITY${NC}"

# Step 1: Initialize git repo if needed
if [[ -d .git ]]; then
    echo -e "\n${YELLOW}Git repository already initialized, skipping...${NC}"
else
    echo -e "\n${YELLOW}Initializing git repository...${NC}"
    git init
fi

# Step 2: Add Python .gitignore if not present
if [[ -f .gitignore ]]; then
    echo -e "\n${YELLOW}.gitignore already exists, skipping...${NC}"
else
    echo -e "\n${YELLOW}Fetching Python .gitignore from GitHub...${NC}"
    curl -sL https://raw.githubusercontent.com/github/gitignore/main/Python.gitignore -o .gitignore
    echo -e "${GREEN}.gitignore created${NC}"
fi

# Step 3: Create remote repository on GitHub
echo -e "\n${YELLOW}Creating remote repository on GitHub...${NC}"

# Check if remote 'origin' already exists
if git remote get-url origin &>/dev/null; then
    echo -e "${YELLOW}Remote 'origin' already exists:${NC}"
    git remote get-url origin
    echo -e "${YELLOW}Skipping remote creation...${NC}"
else
    if [[ "$VISIBILITY" == "public" ]]; then
        gh repo create "$EXPECTED_USER/$REPO_NAME" --public --source=. --remote=origin
    else
        gh repo create "$EXPECTED_USER/$REPO_NAME" --private --source=. --remote=origin
    fi
    echo -e "${GREEN}Remote repository created: https://github.com/$EXPECTED_USER/$REPO_NAME${NC}"
fi

# Step 4: Stage, commit, and push
echo -e "\n${YELLOW}Staging all files...${NC}"
git add .

# Check if there are changes to commit
if git diff --cached --quiet; then
    echo -e "${YELLOW}No changes to commit${NC}"
else
    echo -e "${YELLOW}Creating initial commit...${NC}"
    git commit -m "Initial commit"
fi

# Determine default branch name
DEFAULT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")

echo -e "\n${YELLOW}Pushing to remote...${NC}"
git push -u origin "$DEFAULT_BRANCH"

echo -e "\n${GREEN}=== Done! ===${NC}"
echo -e "Repository: https://github.com/$EXPECTED_USER/$REPO_NAME"
