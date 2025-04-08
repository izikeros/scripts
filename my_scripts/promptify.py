#!/usr/bin/env python3
"""Create a prompt file with code and context from a Python project.

The context convey structure of the code - functions, classes, methods with their signatures and docstrings.
"""
import argparse
import glob
import os
from pprint import pprint


def create_prompt_file(directory: str, instruction: str, file_extensions: list[str], exclude: list[str], system_role: str) -> None:
    included_files: list[str] = []
    structure = "Project structure:\n"

    _collect_files(directory, exclude, file_extensions, included_files)

    # structure of the project (only included files)
    for file in included_files:
        structure += f"{file}\n"

    # add code from each file to the prompt file
    sources = "Project content:\n"
    files = {}
    for file_path in included_files:
        with open(file_path) as f:
            code = f.read()
            if code:
                files[file_path] = len(code) / 4
                sources += f"# file: {file_path}\n"
                sources += f"{code}\n\n"

    prompt = f"{system_role}\n{instruction}\n{structure}\n{sources}"

    with open("prompt.txt", "w") as f:
        f.write(prompt)

    print("Prompt file created: prompt.txt")
    print(f"Approximate number of tokens: {int(len(prompt) / 4)}")
    # sort files dict by value, descending
    files = dict(sorted(files.items(), key=lambda item: item[1], reverse=True))
    pprint(files)


def _collect_files(directory: str, exclude: list[str], file_extensions: list[str], included_files: list[str]) -> None:
    files: list[str] = []
    # use glob to find files with the given extensions
    for ext in file_extensions:
        files.extend(glob.glob(f"**/*{ext}", recursive=True))
    # remove files in the .git, .vscode, .idea directories
    files = [
        file
        for file in files
        if ".git" not in file and ".vscode" not in file and ".idea" not in file
    ]
    # remove files in the __pycache__ directory
    files = [file for file in files if "__pycache__" not in file]
    # remove files from outdated directory
    files = [file for file in files if "outdated" not in file]
    # remove excluded files
    files = [file for file in files if file not in exclude]
    # write structure of the project to the prompt file (write full path of each file)
    for file in files:
        file_path = os.path.join(directory, file)
        included_files.append(file_path)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Create a prompt file with code and context from a Python project."
    )
    parser.add_argument("directory", help="The directory of the Python project.")
    parser.add_argument(
        "--system-role",
        default="You are and experienced, senior full-stack developer.",
        help="The instruction for the prompt. Defaults to 'Find potential bugs in the code below'.",
    )
    parser.add_argument(
        "--instruction",
        default="Analyze project described below and find potential bugs in the code.\nSource code of the project files starts from the line with comment like this: # file: ./app2.py",
        help="The instruction for the prompt. Defaults to 'Find potential bugs in the code below'.",
    )
    parser.add_argument(
        "--extensions",
        nargs="+",
        default=[".py"],
        help="File extensions to include. Specify multiple extensions separated by spaces. Defaults to '.py'.",
    )

    parser.add_argument(
        "--exclude",
        nargs="+",
        default=[""],
        help="Files to exclude. Specify multiple files separated by spaces. Empty by default",
    )

    args = parser.parse_args()
    create_prompt_file(
        args.directory,
        args.instruction,
        args.extensions,
        args.exclude,
        args.system_role,
    )


if __name__ == "__main__":
    main()
