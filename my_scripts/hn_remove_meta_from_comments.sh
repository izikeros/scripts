#!/bin/bash

# Function to display help
usage() {
    echo "Usage: $0 [OPTIONS] [FILE]"
    echo ""
    echo "Remove Hacker News comment metadata from input."
    echo ""
    echo "Options:"
    echo "  -h, --help     Display this help message"
    echo "  -r, --remove   Remove lines with the original author completely"
    echo ""
    echo "If no file is specified, reads from standard input."
    echo ""
    echo "Examples:"
    echo "  $0 input.txt"
    echo "  cat input.txt | $0"
    echo "  $0 -r input.txt"
}

# Default behavior
remove_author_line=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -r|--remove)
            remove_author_line=true
            shift
            ;;
        *)
            # Treat as input file if it's not an option
            input_file="$1"
            shift
            ;;
    esac
done

# Function to process comments
process_comments() {
    local input="$1"

    if [ "$remove_author_line" = true ]; then
        # Completely remove lines with "points by" and lines with time metadata
        grep -v "points by" "$input" | \
        grep -Ev "^[^ ]+\s+\d+\s+.*ago\s*\|" | \
        sed '/^$/d'
    else
        # Just extract usernames
        grep -v "points by" "$input" | \
        sed -E 's/^([^ ]+) .*ago \|.*$/\1/' | \
        sed '/^$/d'
    fi
}

# Determine input source
if [ -n "$input_file" ]; then
    # If input file is specified
    process_comments "$input_file"
else
    # Read from stdin
    process_comments /dev/stdin
fi
