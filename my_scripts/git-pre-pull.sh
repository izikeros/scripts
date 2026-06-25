#!/bin/bash

# fetch info about changes in upstream
git fetch --all
echo
echo " -------------- COMMITS -------------------"
# display info on commit
git --no-pager log ..@{upstream} --abbrev-commit --pretty=format:'%C(yellow)%h%C(reset) - %s (%C(green)%ar%C(reset)) %C(blue)<%an>%C(reset)'
echo
echo
echo " -------------- MODIFIED FILES ------------"
# list modified files
git diff --stat ..@{upstream}
echo
