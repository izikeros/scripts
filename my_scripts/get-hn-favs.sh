#!/usr/bin/env bash
# author: Krystian Safjan (ksafjan@gmail.com)
# Licence MIT

set -e

# fetch my hackernews favourites and save to csv
HN_FAV_FNAME=$HOME/data/hn_favs.csv
if [ -f "$HN_FAV_FNAME" ]; then
    echo "File $HN_FAV_FNAME exists. Will append to it."
    # get only latest favs if file already exists
    "$HOME"/dotfiles/scripts/append_hn_favs.sh
else
    # get all favs
    # TODO: replace with similar bash downloader as for github stars (see: getstarred.sh)
    echo "File $HN_FAV_FNAME does not exist. Will create it."
    "$HOME"/projects/priv/hacker-news-favourites-downloader/hafado.py -u izik > "$HN_FAV_FNAME"
fi
echo "Done"
