#!/usr/bin/env bash
#
# Script that stages and commit all changes in vimwiki folder
#
# usage:
# 	ron-700-commit-vimwiki-changes.sh
#
echo "-- vimwiki commit changes --"
cd ~/vimwiki || exit
git add . && git commit -m "update" 2>/dev/null && echo "vimwiki changes commited"

