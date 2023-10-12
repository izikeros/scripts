#!/bin/bash
# chuj-dl — download music from chomikuj.pl
#
# Usage:
#   chuj-dl URL1 URL2 ...
#
# Example:
#   chuj-dl 'http://chomikuj.pl/J.D.a.d.1980/Music+Poland/Psychocukier/(2013)++Diamenty/07+-+Psychocukier+-+Czas,3468766147.mp3' 'http://another-url.com/somefile.mp3'

for URL in "$@"; do
    TMP="$(mktemp /tmp/chujdl.XXXXXX)"

    # Download the URL, get the metadata
    echo -n "Downloading metadata for https://chomikuj.pl$URL... " >&2
    wget "https://chomikuj.pl$URL" -O- -q > "$TMP"
    echo "done" >&2

    # Fetch real music URL and original filename
    FILEURL="$(cat "$TMP" | grep data-fileid | cut -d\" -f14 | sed 's/&amp;/\&/g')"
    FILENAME="$(cat "$TMP" | grep data-fileid | cut -d\" -f6 | sed 's/&amp;/\&/g')"

    echo "Downloading $FILENAME..."

    # Remove a temporary file
    rm -rf "$TMP"

    # Download the file
    wget "$FILEURL" -O "$FILENAME"
done
