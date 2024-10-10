#!/bin/bash

# File containing JSON data
json_file="$HOME/projects/priv/hn_text_and_comments_downloader/data/hn_favorites-latest.json"

# Use jq to filter and format the JSON data for fzf
selected=$(jq -r '.[] | "\(.title) \(.id)"' "$json_file" | fzf --prompt="Select a post: " --exact)

# Extract the ID of the selected item
selected_id=$(echo "$selected" | awk '{print $NF}')

# Use jq to get the hn_link of the selected item
hn_link=$(jq -r --arg id "$selected_id" '.[] | select(.id == $id) | .hn_link' "$json_file")

# Open the hn_link in the default browser
if [[ -n "$hn_link" ]]; then
  open "$hn_link"
else
  echo "No link found for the selected item."
fi
