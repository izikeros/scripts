#!/usr/bin/env python3
import argparse
import os
import sys


def show_help():
    print(f"Usage: {os.path.basename(__file__)} [DIRECTORY]")
    print()
    print("Extract TODO and FIXME from python files. Count number of occurrences.")
    print()
    print("Options:")
    print("  -h, --help    Show this help message and exit")


def find_todos_and_fixmes(directory):
    todos = []
    for root, _, files in os.walk(directory):
        if ".venv" in root:
            continue
        for file in files:
            if file.endswith(".py"):
                file_path = os.path.join(root, file)
                with open(file_path, encoding="utf-8") as f:
                    for line_num, line in enumerate(f, start=1):
                        if "TODO" in line or "FIXME:" in line:
                            todos.append((file_path, line_num, line.strip()))
    return todos


def main(directory):
    todos = find_todos_and_fixmes(directory)

    # Determine the longest string in the first part
    max_length = 0
    formatted_todos = []
    for file_path, line_num, line in todos:
        first_part = f"{file_path}:{line_num:<5} {line.split('#', 1)[0].strip()}"
        if len(first_part) > 90:
            first_part = first_part[:87] + "..."
        formatted_todos.append((first_part, line))
        max_length = max(max_length, len(first_part))

    # Print the formatted output in two columns
    for first_part, line in formatted_todos:
        second_part = line.split("#", 1)[1].strip() if "#" in line else ""
        print(f"{first_part:<{max_length}} # {second_part}")

    # Print the count
    print(len(todos))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Extract TODO and FIXME from python files. Count number of occurrences."
    )
    parser.add_argument(
        "directory",
        nargs="?",
        default=".",
        help="Directory to search (default: current directory)",
    )
    args = parser.parse_args()

    if args.directory in ("-h", "--help"):
        show_help()
        sys.exit(0)

    main(args.directory)
