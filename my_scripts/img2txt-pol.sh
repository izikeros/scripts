#!/bin/bash
# source: https://winsmarts.com/clipboard-image-to-text-via-ocr-a65d4e7f6482
screencapture -i /tmp/scr_img.png
tesseract /tmp/scr_img.png /tmp/output -l pol 2> /dev/null
cat /tmp/output.txt | pbcopy
rm /tmp/scr_img.png
