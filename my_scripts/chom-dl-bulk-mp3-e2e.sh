#!/bin/bash
# chomikuj-dl-bulk.sh — download multiple mp3 files from chomikuj.pl

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
    echo "Missing URL"
    echo "Usage: $0 <URL> <pattern>"
    exit 1
fi

# Check if pattern argument is provided
if [ -z "$2" ]; then
    echo "Missing pattern"
    echo "Usage: $0 <URL> <pattern>"
    exit 1
fi
pattern="$2"

# Fetch and extract links from the provided URL
links=$(fetch_and_extract_links "$1")

# Filter links for mp3 files containing the pattern "Taleb"
filtered_links=$(echo "$links" | grep '.mp3' | grep "$pattern")

# Download files in parallel using xargs
echo "$filtered_links" | xargs -P 4 -I {} chom-dl-bulk.sh "https://chomikuj.pl{}"
