#!/bin/bash
set -e

while [ -n "$1" ]
do
case "$1" in
-d) ~/scripts/my_scripts/get_starred.py ;;
*) echo "$1 is not an option" ;;
esac
shift
done
FILE=$HOME/projects/ext/filter-and-sort-dynamically-created-table-with-vanilla-javascript-demo/js/orders.js
echo "Last update of GitHub Stars (use -d to download fresh info):"
#[ -f $FILE date -r $FILE "+%m-%d-%Y %H:%M:%S" ]
date -r "$FILE" "+%m-%d-%Y %H:%M:%S"
cd ~/projects/ext/filter-and-sort-dynamically-created-table-with-vanilla-javascript-demo
python3 -m http.server 9000 &
open "http://localhost:9000"
