#!/usr/bin/env bash
# based on source: https://winsmarts.com/clipboard-image-to-text-via-ocr-a65d4e7f6482

#set -o xtrace
#set -e
#OUTPUT_TXT_FILE="/tmp/output.txt"
#OUTPUT_IMG_FILE="/tmp/scr_img.png"
#
## ensure the file is not there (delete it)
[ -f "/tmp/output.txt" ] && rm "/tmp/output.txt"
[ -f "/tmp/scr_img.png" ] && rm "/tmp/scr_img.png"

# do the ocr and redirect errors to /dev/null
current_dir=$(pwd)
cd /tmp || exit

screencapture -i scr_img.png
#echo "..Captured"
tesseract "scr_img.png" /tmp/output 2> /dev/null
#echo "..OCR done"
#echo "------"
#cat /tmp/output.txt
#echo "------"
pbcopy < /tmp/output.txt
#echo "..Copied to clipboard"
# display the text - how many characters were copied
#cat /tmp/output.txt | wc -m

# Clean-up: delete the files
[ -f "/tmp/output.txt" ] && rm "/tmp/output.txt"
[ -f "/tmp/scr_img.png" ] && rm "/tmp/scr_img.png"
#echo "..Cleaned. Done"
cd "$current_dir" || exit
