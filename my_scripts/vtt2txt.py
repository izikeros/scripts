#!/usr/bin/env python3
"""Convert VTT subtitles to TXT.

- Skip first 4 lines of VTT file.
- remove all lines containing "-->".
- remove all new lines
usage: vtt2txt.py [-h] [-o OUTPUT] input

use file selector on mac
fzf | tr \\n \\0 | xargs -0 vtt2txt.py
"""

import argparse
import os


def remove_lines_with_arrow(list_of_lines):
    """Remove lines containing -->."""
    return [line for line in list_of_lines if "-->" not in line]


def remove_first_lines(list_of_lines, n):
    """Remove first n lines."""
    return list_of_lines[n:]


def remove_new_lines(list_of_lines):
    """Remove new lines."""
    return [line.replace("\n", " ") for line in list_of_lines]


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", help="Input VTT file")
    parser.add_argument("-o", "--output", help="Output TXT file")
    args = parser.parse_args()

    if not args.output:
        args.output = os.path.splitext(args.input)[0] + ".txt"

    with open(args.input) as f:
        lines = f.readlines()

    lines = remove_first_lines(lines, 4)
    lines = remove_lines_with_arrow(lines)
    lines = remove_new_lines(lines)

    txt = "".join(lines)
    txt = txt.replace("\n", "")

    # replace more than one space with one space
    txt = " ".join(txt.split())

    with open(args.output, "w") as f:
        f.writelines(lines)
