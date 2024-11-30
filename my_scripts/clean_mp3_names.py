#!/usr/bin/env python3
import os
import re


def clean_filename(filename):
    # Remove text within parentheses or square brackets
    cleaned = re.sub(r"\([^)]*\)|\[[^]]*\]", "", filename)

    # Remove file extension
    name_without_ext = os.path.splitext(cleaned)[0]

    # Strip whitespace from the core filename
    stripped_name = name_without_ext.strip()

    # replace spaces with underscores
    stripped_name = stripped_name.replace(" ", "_")

    # Add the extension back
    return stripped_name + ".mp3"


# Get all MP3 files in the current directory
mp3_files = [f for f in os.listdir(".") if f.lower().endswith(".mp3")]

for old_name in mp3_files:
    new_name = clean_filename(old_name)

    if old_name != new_name:
        try:
            os.rename(old_name, new_name)
            print(f"Renamed: {old_name} -> {new_name}")
        except OSError as e:
            print(f"Error renaming {old_name}: {e}")
