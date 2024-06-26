#!/usr/bin/env bash


FILE_TYPE=${1:-*}
# display the file type only if it is not *
[ "$FILE_TYPE" != "*" ] && echo "F:$FILE_TYPE"
find . -iname "$FILE_TYPE" | while read f
do
  # avoid having error message:
  # mv: . and ./. are identical
  if [ "$f" = "." ] || [ "$f" = "./." ]; then
    continue
  fi
	echo "$f"
	# allowed: letters, numbers and dot, coma and slash. The rest would be replaced by underscore
	nf=$(echo "$f" | sed -e 's/[^A-Za-z0-9/._-]/_/g')
	mv "$f" "$nf"
done
