#!/usr/bin/env python3
import argparse
import re
from pathlib import Path


def remove_bold_from_headings(content):
    """Remove bold formatting from Markdown headings."""
    # Match headings with bold text, capturing the heading level, bold content, and any trailing text
    pattern = r'^(#{1,6}\s+)\*\*(.*?)\*\*(.*)$'

    # Replace with the heading level, the content without bold markers, and trailing text
    return re.sub(pattern, r'\1\2\3', content, flags=re.MULTILINE)


def process_file(file_path, dry_run=False):
    """Process a single Markdown file."""
    with open(file_path, encoding='utf-8') as f:
        content = f.read()

    modified_content = remove_bold_from_headings(content)

    if content != modified_content:
        if dry_run:
            print(f"Would modify: {file_path}")
        else:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(modified_content)
            print(f"Modified: {file_path}")
    # else:
        # print(f"No changes needed: {file_path}")


def main():
    parser = argparse.ArgumentParser(description="Remove bold formatting from Markdown headings")
    parser.add_argument("path", help="File or directory to process")
    parser.add_argument("--dry-run", "-d", action="store_true", help="Show what would be changed without making changes")
    args = parser.parse_args()

    path = Path(args.path)

    if path.is_file() and path.suffix.lower() == '.md':
        process_file(path, args.dry_run)
    elif path.is_dir():
        for md_file in path.glob("**/*.md"):
            process_file(md_file, args.dry_run)
    else:
        print(f"Error: {path} is not a Markdown file or directory")
        return 1

    return 0


if __name__ == "__main__":
    exit(main())
