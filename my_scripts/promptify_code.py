#!/usr/bin/env python3
"""
A script to create a text file containing a prompt with the instruction to find potential bugs in the code below,
and add the content of all *.py files with code and context.

Example:
    python3 create_prompt_with_code.py -i "Find potential bugs in the code below:" -o "prompt_with_code.txt"

    This script will create a text file called `prompt_with_code.txt` containing the provided instruction and
    the content of all `*.py` files in the project. The file path of each Python file is added as context. You can
    customize the instruction and output file path using the `-i` and `-o` flags, respectively.
"""

import argparse
import glob


def create_prompt(instruction, output_file):
    """
    Create a prompt with the given instruction and save it to the output_file.

    Args:
    instruction (str): The instruction for the prompt.
    output_file (str): The path of the output file.
    """
    with open(output_file, "w") as f:
        f.write(instruction + "\n\n")


def add_python_files(output_file):
    """
    Add the content of all *.py files to the output_file with the file path as context.

    Args:
    output_file (str): The path of the output file.
    """
    for filepath in glob.glob("**/*.py", recursive=True):
        with open(output_file, "a") as f:
            f.write(f"File path: {filepath}\n")
        with open(filepath, "r") as py_file:
            f.write(py_file.read())
            f.write("\n\n")


def main():
    parser = argparse.ArgumentParser(
        description="Create a prompt and add Python code from the project."
    )
    parser.add_argument(
        "-i",
        "--instruction",
        default="Find potential bugs in the code below:",
        help="The instruction for the prompt.",
    )
    parser.add_argument(
        "-o",
        "--output",
        default="prompt_with_code.txt",
        help="The path of the output file.",
    )

    args = parser.parse_args()

    create_prompt(args.instruction, args.output)
    add_python_files(args.output)


if __name__ == "__main__":
    main()
