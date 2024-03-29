#!/usr/bin/env bash

~/scripts/my_scripts/getstarred.sh | \
# replace quoted csv with commas separator with unquoted with ^ as separator
sed 's/^\"//g' | sed 's/\",\"/\^/g' | sed 's/\"$//g' | \
# remove duplicates
sort -u | \
# sort by date (recently starred first)
sort -k4 --reverse > ~/data/github-izikeros-stars-desc-ng.txt
