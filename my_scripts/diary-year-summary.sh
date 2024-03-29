#!/usr/bin/env bash
# diary-year-summary.sh - create file (in curent directory) with year summary from the diary entries
# Usage:
# diary-year-summary.sh 2019
# author: Krystian Safjan (ksafjan@gmail.com)
# Licence MIT

set -e

[ -d "/usr/local/opt/coreutils/libexec/gnubin" ] && export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"

find "$HOME/vimwiki/diary" -type f -name '*.md' | \
    grep $1 |\
    xargs head -q -n1 |\
    sed 's/^#\s//' |\
    sort > "./y-$1.txt"
