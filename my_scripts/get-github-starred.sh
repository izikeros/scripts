#!/usr/bin/env bash
# Get starred repositories from GitHub, post-process and save to file
#
# See also: getstarred.sh

OUT_FILE=~/data/github-izikeros-stars-desc-ng.txt

~/scripts/my_scripts/getstarred.sh | \
# replace quoted csv with commas separator with unquoted with ^ as separator
sed 's/^\"//g' | sed 's/\",\"/\^/g' | sed 's/\"$//g' | \
# remove duplicates
sort -u | \
# sort by date (recently starred first)
sort -k4 --reverse > $OUT_FILE

echo "Star info saved to: $OUT_FILE"

# count lines
wc -l $OUT_FILE