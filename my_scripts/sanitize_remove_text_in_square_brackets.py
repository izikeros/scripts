#!/usr/bin/env python3
import os
import re

DRY_RUN = False

# Set directory to the dir where it is called from
directory = os.getcwd()

# Regex pattern to match square brackets and their content
pattern = r'\[.*?\]'

for filename in os.listdir(directory):
    # Get the file path
    filepath = os.path.join(directory, filename)

    # Skip directories
    if os.path.isdir(filepath):
        continue

    # Remove square brackets and their content from the filename
    new_name = re.sub(pattern, '', filename)

    # Replace two or more spaces with a single space
    new_name = re.sub(r' {2,}', ' ', new_name)

    # Ensure we don't try to rename the file if it's already correct
    new_filepath = os.path.join(directory, new_name)
    if not DRY_RUN and new_name != filename:
        try:
            os.rename(filepath, new_filepath)
            print(f"Renamed '{filename}' to '{new_name}'")
        except Exception as e:
            print(f"Error renaming '{filename}': {e!s}")
    elif DRY_RUN:
        print(f"Would rename '{filename}' to '{new_name}'")
