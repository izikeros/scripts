#!/usr/bin/env python3
import argparse
import re

def extract_text_from_vtt(vtt_text):
    # Remove header
    vtt_text = re.sub(r'WEBVTT\nKind: captions\nLanguage: en\n', '', vtt_text)

    # Remove timestamps and display info
    vtt_text = re.sub(r'\d{2}:\d{2}:\d{2}\.\d{3} --> \d{2}:\d{2}:\d{2}\.\d{3} align:start position:0%\n', '', vtt_text)

    # Extract text from markup tags
    vtt_text = re.sub(r'<\d{2}:\d{2}:\d{2}\.\d{3}><c>', ' ', vtt_text)
    vtt_text = re.sub(r'</c>', '', vtt_text)

    # Replace two or more spaces with one space
    vtt_text = re.sub(r' {2,}', ' ', vtt_text)

    # remove lines with only whitespace character(s)
    vtt_text = re.sub(r'^\s+$', '', vtt_text, flags=re.MULTILINE)

    # Remove empty lines
    vtt_text = re.sub(r'\n\n', '\n', vtt_text)

    # Remove repeated subsequent lines
    lines = vtt_text.split('\n')
    lines = [line for i, line in enumerate(lines) if i == 0 or line != lines[i-1]]

    return '\n'.join(lines)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", help="Input VTT file")
    args = parser.parse_args()


    with open(args.input) as f:
        lines = f.readlines()


    subs = "".join(lines)
    text = extract_text_from_vtt(subs)
    print(text)
