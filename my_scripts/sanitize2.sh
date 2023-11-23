#!/bin/bash
# Filename Sanitization: The script then loops over all files in the current directory
# that match the extension. For each file, it does the following:
#
# It creates a sanitized version of the filename by replacing all characters that
# are not alphanumeric ([:alnum:]), period (.), slash (/), or comma (,) with an underscore (_).
#
# This is done using the tr command with the -c option, which specifies a complement
# set of characters. In other words, it replaces all characters that are not in the specified set.
#
# It then checks if the original filename and the sanitized filename are different.
# If they are, it prints the sanitized filename and renames the file to the sanitized
# filename using the mv command.
#

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
