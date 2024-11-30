#!/usr/bin/env bash
# Extract TODO and FIXME from python files. Count number of occurrences. Align output in two columns.
# author: Krystian Safjan (ksafjan@gmail.com)
# Licence MIT

echo "Use: todoextract.py instead of this script"
# set -e

# #TODO: make date first column, sort by date

# show_help() {
# 	echo "Usage: $(basename "$0") [DIRECTORY]"
# 	echo
# 	echo "Extract TODO and FIXME from python files. Count number of occurrences."
# 	echo
# 	echo "Options:"
# 	echo "  -h, --help    Show this help message and exit"
# }

# # Check for help flag
# if [[ "$1" == "-h" || "$1" == "--help" ]]; then
# 	show_help
# 	exit 0
# fi

# # Use current directory if no argument is provided
# DIR="${1:-.}"

# find "$DIR" -name "*.py" ! -path "*/.venv/*" -print0 | xargs -0 grep -n "TODO:\|FIXME:" | awk -F: '{split($0, a, "#"); printf "%-50s %-s\n", a[1], a[2]}'
# find "$DIR" -name "*.py" ! -path "*/.venv/*" -print0 | xargs -0 grep -n "TODO:\|FIXME:" | wc -l
