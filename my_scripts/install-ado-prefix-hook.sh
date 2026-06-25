#!/bin/bash
# install-commit-msg-hook.sh
# Script to install the Azure DevOps commit-msg hook
set -euo pipefail

echo "Installing Azure DevOps commit-msg hook..."

# Check if we're in a Git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in a Git repository root directory"
    echo "   Please run this script from the root of your Git repository"
    exit 1
fi

# Create the commit-msg hook
cat > .git/hooks/commit-msg << 'EOF'
#!/bin/bash
# .git/hooks/commit-msg
# This script automatically adds Azure DevOps prefix to commit messages
# The commit message file is passed as the first argument
COMMIT_MSG_FILE=$1
# Read the commit message
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")
# Skip if already has prefix, is a merge, or is a revert
if echo "$COMMIT_MSG" | grep -q "^AB#" || echo "$COMMIT_MSG" | grep -q "^Merge" || echo "$COMMIT_MSG" | grep -q "^Revert"; then
    exit 0
fi
# Get current branch name
BRANCH=$(git rev-parse --abbrev-ref HEAD)
# Extract story number from branch name
STORY_NUMBER=$(echo "$BRANCH" | grep -oE 'AB[#-]?[0-9]+' | sed 's/-/#/')
# If story number found, prepend it to the commit message
if [ -n "$STORY_NUMBER" ]; then
    echo "$STORY_NUMBER: $COMMIT_MSG" > "$COMMIT_MSG_FILE"
    echo "✅ Added prefix: $STORY_NUMBER"
else
    echo "⚠️  No Azure DevOps story number found in branch name: $BRANCH"
    echo "   Expected format: feature/AB-1233456-description"
fi
EOF

# Make the hook executable
chmod +x .git/hooks/commit-msg

echo "✅ Azure DevOps commit-msg hook installed successfully!"
echo ""
echo "Usage:"
echo "  - Name your branches like: feature/AB-123456-description"
echo "  - The hook will automatically add AB#123456: to your commit messages"
echo "  - Hook will skip merge commits, reverts, and messages that already have prefixes"
echo ""
echo "Test it by creating a branch with AB-123456 in the name and making a commit!"
