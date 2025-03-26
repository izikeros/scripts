#!/bin/bash

# Function to process input (from file or stdin)
process_comments() {
    # Remove lines with points, flags, etc.
    # Then remove metadata from comment lines using sed
    grep -v "points by" | \
    sed -E 's/^([^ ]+) .*ago \|.*$/\1/' | \
    # Remove empty lines
    sed '/^$/d'
}

# Check if input is from a file or stdin
if [ $# -gt 0 ]; then
    # If file is provided, process the file
    process_comments < "$1"
else
    # Otherwise, read from stdin
    process_comments
fi