#!/usr/bin/env python3

import re
import sys


def vtt_to_text(vtt_content, remove_duplicates=True):
    # Remove header lines (usually just "WEBVTT" and metadata)
    lines = vtt_content.strip().split("\n")
    if lines and "WEBVTT" in lines[0]:
        # Skip headers until we find a timestamp line
        i = 0
        while i < len(lines) and not re.match(r"^\d{2}:\d{2}:\d{2}", lines[i]):
            i += 1
        lines = lines[i:]

    # Process content
    text_parts = []
    current_text = ""
    last_added_text = None  # Track the last added text for duplicate detection

    for line in lines:
        # Skip timestamp lines
        if re.match(r"^\d{2}:\d{2}:\d{2}", line) or line.strip() == "":
            continue

        # Clean text: remove all content in angle brackets
        cleaned_line = re.sub(r"<[^>]+>", "", line)

        # Add non-empty lines to the result
        if cleaned_line.strip():
            current_text += " " + cleaned_line.strip()
            if current_text.strip():
                # Only add if not a duplicate of the previous line or if duplicates are allowed
                if not remove_duplicates or current_text.strip() != last_added_text:
                    text_parts.append(current_text.strip())
                    last_added_text = current_text.strip()
                current_text = ""

    # Join all text parts with space
    return " ".join(text_parts)


def process_file(input_file, output_file=None, remove_duplicates=True):
    if output_file is not None:
        # replace extension by adding .txt, even if file has already an extension
        output_file = output_file + ".txt"

    try:
        with open(input_file, encoding="utf-8") as f:
            vtt_content = f.read()

        text = vtt_to_text(vtt_content, remove_duplicates)

        if output_file:
            with open(output_file, "w", encoding="utf-8") as f:
                f.write(text)
            print(f"Successfully converted {input_file} to {output_file}")
        else:
            print(text)

    except Exception as e:
        print(f"Error processing file: {e}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python vtt_to_text.py input.vtt [output.txt] [--keep-duplicates]")
        sys.exit(1)

    input_file = sys.argv[1]

    # Parse command line arguments
    output_file = None
    remove_duplicates = True

    for arg in sys.argv[2:]:
        if arg == "--keep-duplicates":
            remove_duplicates = False
        elif not output_file:  # First non-flag argument is the output file
            output_file = arg

    process_file(input_file, output_file, remove_duplicates)
