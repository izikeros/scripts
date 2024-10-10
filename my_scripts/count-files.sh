#!/usr/bin/env sh
# count-files.sh - count files in each dir in current directory
#

for i in */; do
    i="${i%/}"
    num_files=$(find "$i" -type f | wc -l)
    printf "%6d: %s\n" "$num_files" "$i"
done
