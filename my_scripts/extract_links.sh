#!/bin/bash

# Function to fetch website content and extract links
fetch_and_extract_links() {
    url="$1"
    user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3"

    # Fetch the website content using curl
    content=$(curl -A "$user_agent" -sSL "$url")

    # Extract all links using grep and sed
    links=$(echo "$content" | grep -oE 'href="([^"#]+)"' | sed -E 's/href="([^"#]+)"/\1/g')

    echo "$links"
}

# Check if URL argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <URL>"
    exit 1
fi

# Fetch and extract links
fetch_and_extract_links "$1"
