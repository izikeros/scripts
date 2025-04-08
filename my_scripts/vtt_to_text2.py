#!/usr/bin/env python3

import re
import sys


def vtt_to_text(vtt_content):
    # Remove header lines (usually just "WEBVTT" and metadata)
    lines = vtt_content.strip().split('\n')
    if lines and "WEBVTT" in lines[0]:
        # Skip headers until we find a timestamp line
        i = 0
        while i < len(lines) and not re.match(r'^\d{2}:\d{2}:\d{2}', lines[i]):
            i += 1
        lines = lines[i:]

    # Process content
    text_parts = []
    current_text = ""

    for line in lines:
        # Skip timestamp lines
        if re.match(r'^\d{2}:\d{2}:\d{2}', line) or line.strip() == '':
            continue

        # Clean text: remove all content in angle brackets
        cleaned_line = re.sub(r'<[^>]+>', '', line)

        # Add non-empty lines to the result
        if cleaned_line.strip():
            current_text += " " + cleaned_line.strip()
            if current_text.strip():
                text_parts.append(current_text.strip())
                current_text = ""

    # Join all text parts with space
    return ' '.join(text_parts)

def process_file(input_file, output_file=None):
    try:
        with open(input_file, encoding='utf-8') as f:
            vtt_content = f.read()

        text = vtt_to_text(vtt_content)

        if output_file:
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(text)
            print(f"Successfully converted {input_file} to {output_file}")
        else:
            print(text)

    except Exception as e:
        print(f"Error processing file: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python vtt_to_text.py input.vtt [output.txt]")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    process_file(input_file, output_file)
