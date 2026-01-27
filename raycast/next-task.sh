#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title next task
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.description Track next task to do
# @raycast.author Krystian Safjan
# @raycast.authorURL https://safjan.com

# Create the file if it doesn't exist
TASKS_FILE="$HOME/Documents/next-tasks.txt"
if [ ! -f "$TASKS_FILE" ]; then
    echo "# Next Tasks - $(date)" > "$TASKS_FILE"
    echo "" >> "$TASKS_FILE"
    echo "## Today:" >> "$TASKS_FILE"
    echo "- " >> "$TASKS_FILE"
fi

# Open in Zed
echo "## $(date '+%A, %B %d, %Y - %H:%M')" >> "$TASKS_FILE"
echo "### Next Actions:" >> "$TASKS_FILE"
echo "- [ ] " >> "$TASKS_FILE"
open -a "Zed" "$TASKS_FILE"
