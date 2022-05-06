#!/usr/bin/env bash

# author: Krystian Safjan (ksafjan@gmail.com)
# License: MIT

FILES="boots.log
coingecko_data.json
github-izikeros-stars-desc-ng.txt
hn_favs.csv
"

for f in $FILES
do
	if [[ -f "$HOME/data/$f" ]]; then
        MODDATE=$(stat -c %y "$HOME"/data/"$f")
	    MODDATE=${MODDATE%% *}
        NUM_LINES=$(wc -l < "$HOME/data/$f")
        FILESIZE=$(stat -c %s "$HOME/data/$f" | numfmt --to=iec)
        echo "$MODDATE - $f ($FILESIZE, $NUM_LINES lines)"
    else
        echo "$HOME/data/$f not exists"
    fi
done
