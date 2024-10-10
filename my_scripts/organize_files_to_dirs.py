#!/usr/bin/env python3

"""
organize_files.py

This script organizes files in the current directory by creating a new directory
for each file and moving the file into it. The new directory name is based on
the file name without its extension, with spaces replaced by underscores.

Usage: Place this script in the directory containing the files you want to
organize, then run it.

Note: This script will not process subdirectories, only files in the current
directory.
"""

import os
import shutil

# Get the current directory
current_dir = os.getcwd()

# Iterate through all items in the directory
for item in os.listdir(current_dir):
    # Check if it's a file (not a directory)
    if os.path.isfile(item):
        # Get the file name without extension
        file_name = os.path.splitext(item)[0]
        
        # Replace spaces with underscores
        dir_name = file_name.replace(' ', '_')
        
        # Create the new directory if it doesn't exist
        if not os.path.exists(dir_name):
            os.makedirs(dir_name)
        
        # Move the file into the new directory
        shutil.move(item, os.path.join(dir_name, item))

print("Operation completed successfully.")