#!/bin/bash

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
echo "Usage: ./sanitize_filenames.sh [extension]"
echo "If no extension is provided, all files will be sanitized."
exit 0
fi

extension="$1"
if [ -z "$extension" ]; then
extension="*"
fi

for filename in *.$extension; do
sanitized_filename=$(echo "$filename" | tr -c '[:alnum:]./,' '_')
if [ "$filename" != "$sanitized_filename" ]; then
    echo "$sanitized_filename"
    mv "$filename" "$sanitized_filename"
fi
done
