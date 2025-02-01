#!/usr/bin/env python3
"""
Here's how the script works:

1. It sets the source directory and destination directory.
2. It gets a list of all files in the source directory.
3. It creates a set to store unique base names.
4. It loops through each file and checks if it's a mkv/webm video or an mp3 audio file. If it is, it gets the base name without extension and adds it to the set.
5. It loops through each unique base name and creates a directory for it in the destination directory.
6. It loops through each file again and checks if it belongs to the current base name. If it does, it moves the file to the destination directory.

Note that this script assumes that the source directory contains only mkv/webm videos and mp3 audio files. If there are other file types, you may need to modify the script to handle them correctly.

Also, make sure to replace `'/path/to/source/directory'` and `'/path/to/destination/directory'` with the actual paths to your source and destination directories.
"""
import os
import shutil

# Set the source directory
src_dir = "/Volumes/media/Natalia/Webinary/Anna_Kupisz"

# Set the destination directory
dst_dir = "/Volumes/media/Natalia/Webinary/Anna_Kupisz"

# Get a list of all files in the source directory
files = os.listdir(src_dir)

# Create a set to store unique base names
base_names = set()

# Loop through each file
for file in files:
    # Get the file name and extension
    name, ext = os.path.splitext(file)
    # Check if the file is a mkv/webm video or an mp3 audio file
    if ext in [".mkv", ".webm"]:
        # Get the base name without extension
        base_name = os.path.basename(name)
    elif ext == ".mp3":
        # Get the base name without extension
        base_name = os.path.basename(name)
    else:
        # Skip other files
        continue

    # Add the base name to the set
    base_names.add(base_name)

# Loop through each unique base name
for base_name in base_names:
    # Create a directory for the base name
    dst_dir_path = os.path.join(dst_dir, base_name)
    os.makedirs(dst_dir_path, exist_ok=True)

    # Loop through each file again
    for file in files:
        # Get the file name and extension
        name, ext = os.path.splitext(file)
        # Check if the file is a mkv/webm video or an mp3 audio file
        if ext in [".mkv", ".webm"]:
            # Get the base name without extension
            file_base_name = os.path.basename(name)
        elif ext == ".mp3":
            # Get the base name without extension
            file_base_name = os.path.basename(name)
        else:
            # Skip other files
            continue

        # Check if the file belongs to the current base name
        if file_base_name == base_name:
            # Move the file to the destination directory
            src_file_path = os.path.join(src_dir, file)
            dst_file_path = os.path.join(dst_dir_path, file)
            shutil.move(src_file_path, dst_file_path)
