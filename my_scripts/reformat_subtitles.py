#!/usr/bin/env python3
"""Script to reformat subtitles.

Usage: reformat_subtitles.py input_filename

Example:
    $ reformat_subtitles.py subtitles.srt

    This will create a new file subtitles.srt_reformatted
    Reformatting means:
    - removing extra line breaks within sentences
    - adding line breaks after sentence end
    - removing extra line breaks at the end of the file
    - removing extra line breaks at the beginning of the file
    - removing extra line breaks at the beginning of the line
"""
import sys

if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} input_filename")
    sys.exit(1)

input_filename = sys.argv[1]

with open(input_filename) as input_file:
    input_text = input_file.read()

# Remove extra line breaks within sentences
output_text = input_text.replace("\n", " ")

# Add line breaks after sentence end
output_text = output_text.replace(". ", ".\n")
output_text = output_text.replace("! ", "!\n")
output_text = output_text.replace("? ", "?\n")

# Write output to a new file
output_filename = input_filename + "_reformatted"
with open(output_filename, "w") as output_file:
    output_file.write(output_text)
