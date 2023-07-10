#!/bin/bash
#
# on mac os install:
# brew install p7zip
# brew install --cask rar
# brew install unzip

target_dir="${1:-.}"  # Use the first command-line argument as the target directory, defaulting to the current directory if not provided

# Go to the target directory
cd "$target_dir" || exit

# Loop through all files in the directory
for file in *; do
  # Check if the file is an archive
  if [[ -f $file && $file =~ \.(rar|zip|7z)$ ]]; then
    # Determine the archive type
    if [[ $file =~ \.rar$ ]]; then
      # Unrar the file
      unrar x "$file"
    elif [[ $file =~ \.zip$ ]]; then
      # Unzip the file
      unzip "$file"
    elif [[ $file =~ \.7z$ ]]; then
      # Un7z the file
      7z x "$file"
    fi
  fi
done

