#!/usr/bin/env python3

import re
import argparse
import sys
import html
from typing import TextIO, Optional
from collections import defaultdict

def get_unique_initials(name: str, used_initials: set) -> str:
    words = name.split()
    initials = ''.join(word[0].upper() for word in words if word)
    
    if not initials:
        return name  # Return full name if we can't create initials

    unique_initials = initials
    i = 1
    while unique_initials in used_initials:
        unique_initials = initials + ''.join(word[1:i+1] for word in words if len(word) > i)
        i += 1
        if i > max(len(word) for word in words):
            return name  # Return full name if we can't create unique initials

    used_initials.add(unique_initials)
    return unique_initials

def filter_vtt(input_file: str, output: TextIO, filter_speaker: bool = True, filter_timestamp: bool = True, merge_lines: bool = False, shorten_speaker: bool = False, only_mapping: bool = False) -> None:
    with open(input_file, 'r') as infile:
        # Skip the first line (WEBVTT)
        next(infile)
        
        current_text = ""
        current_speaker = ""
        used_initials = set()
        speaker_initials = {}

        for line in infile:
            line = line.strip()
            
            # Skip empty lines
            if not line:
                if merge_lines and current_text and not only_mapping:
                    output.write(f"{current_speaker}{html.unescape(current_text.strip())}\n")
                    current_text = ""
                    current_speaker = ""
                continue
            
            # Filter out timestamps if specified
            if filter_timestamp and re.match(r'\d{2}:\d{2}:\d{2}\.\d{3} --> \d{2}:\d{2}:\d{2}\.\d{3}', line):
                continue
            
            # Handle speaker names
            speaker_match = re.match(r'<v ([^>]+)>', line)
            if speaker_match:
                speaker_name = speaker_match.group(1)
                if shorten_speaker or only_mapping:
                    if speaker_name not in speaker_initials:
                        speaker_initials[speaker_name] = get_unique_initials(speaker_name, used_initials)
                    current_speaker = f"[{speaker_initials[speaker_name]}] "
                elif not filter_speaker:
                    current_speaker = f"[{speaker_name}] "
                else:
                    current_speaker = ""
                
                line = re.sub(r'<v [^>]+>|</v>', '', line)
            
            # Decode HTML entities
            line = html.unescape(line)
            
            # Write the filtered line to the output
            if line and not only_mapping:
                if merge_lines:
                    if current_text and current_speaker:
                        output.write(f"{current_speaker}{current_text.strip()}\n")
                        current_text = ""
                    current_text += " " + line
                else:
                    output.write(f"{current_speaker}{line}\n")

    if merge_lines and current_text and not only_mapping:
        output.write(f"{current_speaker}{html.unescape(current_text.strip())}\n")

    if only_mapping and speaker_initials:
        for full_name, initials in speaker_initials.items():
            output.write(f"{initials}: {full_name}\n")

def main() -> None:
    parser = argparse.ArgumentParser(description='Filter VTT transcript from MS Teams')
    parser.add_argument('input_file', help='Input VTT file')
    parser.add_argument('-o', '--output', type=argparse.FileType('w'), default=sys.stdout, help='Output file (default: stdout)')
    parser.add_argument('--keep-speaker', action='store_true', help='Keep speaker names')
    parser.add_argument('--keep-timestamp', action='store_true', help='Keep timestamps')
    parser.add_argument('--merge-lines', action='store_true', help='Merge lines from the same speaker')
    parser.add_argument('--shorten-speaker', action='store_true', help='Shorten speaker names to unique initials')
    parser.add_argument('--only-mapping', action='store_true', help='Display only the speaker mapping (implies --shorten-speaker)')
    
    args = parser.parse_args()
    
    # If --only-mapping is used, automatically set shorten_speaker to True
    if args.only_mapping:
        args.shorten_speaker = True
    
    try:
        filter_vtt(args.input_file, args.output, 
                   filter_speaker=not args.keep_speaker, 
                   filter_timestamp=not args.keep_timestamp,
                   merge_lines=args.merge_lines,
                   shorten_speaker=args.shorten_speaker,
                   only_mapping=args.only_mapping)
        
        if args.output != sys.stdout:
            print(f"Filtered transcript saved to {args.output.name}", file=sys.stderr)
    except IOError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        if args.output != sys.stdout:
            args.output.close()

if __name__ == "__main__":
    main()