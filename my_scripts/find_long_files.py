#!/usr/bin/env python3
"""List all files in a directory tree (recursively) sorted by number of lines"""
import argparse
import os


def get_list_of_files_in_dir(dir_path: str, ext: str) -> list[str]:
    """Get list of files in a directory (recursively) filtered by extension.

    return with yeld"""
    for root, _, files in os.walk(dir_path):
        for file in files:
            if file.endswith(ext):
                yield os.path.join(root, file)


def count_lines_in_file(file_path: str) -> int:
    """Count number of lines in a file."""
    with open(file_path) as f:
        return sum(1 for _ in f)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Display files sorted by number of lines."
    )
    # positional arguments
    parser.add_argument("input_dir", help="Directory with the code to analyse.")

    # named parameters
    parser.add_argument(
        "-e",
        "--extension",
        help="Limit search to files with specific extension, eg. '.py'",
        type=str,
        default=".py",
    )

    parser.add_argument(
        "-l",
        "--min_length",
        help="Display only files with this length or more",
        type=int,
        default=0,
    )

    args = parser.parse_args()

    files = get_list_of_files_in_dir(dir_path=args.input_dir, ext=args.extension)
    # create dictionary of file path and number of lines sorted descending
    files = {file: count_lines_in_file(file) for file in files}
    files = dict(sorted(files.items(), key=lambda item: item[1], reverse=True))
    for file, lines in files.items():
        if lines > args.min_length:
            print(f"{file}:{lines}")
