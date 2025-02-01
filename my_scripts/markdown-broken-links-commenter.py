#!/usr/bin/env python3
"""Check markdown file for broken links and create output markdown document with
broken links annotated with HTML comment."""

import argparse
import re
import urllib.request


def check_markdown_file(input_file, output_file, comment_out=False, quiet=False):
    num_broken_links = 0
    num_working_links = 0

    # Read the input markdown file
    with open(input_file) as f:
        lines = f.readlines()

    # Check each line for a link
    broken_links = []
    for line in lines:
        if match := re.search(r"\[.*]\((.*)\)", line):
            link = match[1]
            if not quiet:
                print(f"Checking link: {link}", end=" ")
            try:
                # Try to open the link
                urllib.request.urlopen(link)
                if not quiet:
                    print("OK")
                num_working_links += 1
            except urllib.error.URLError:
                # If the link is broken, add it to the list of broken links
                broken_links.append(link)
                if not quiet:
                    print("Broken")
                num_broken_links += 1
            except ValueError:
                if not quiet:
                    print("ValueError")

    # Write the output markdown file
    with open(output_file, "w") as f:
        for line in lines:
            if match := re.search(r"\[.*]\((.*)\)", line):
                link = match[1]
                if link in broken_links:
                    # If the link is broken, comment it out
                    if comment_out:
                        f.write(f"<!-- {line.strip()} -->\n")
                    else:
                        f.write(f"<!-- Broken link: --> {line.strip()}\n")
                else:
                    f.write(line)
            else:
                f.write(line)
    return num_working_links, num_broken_links


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Check markdown file for broken links and create output markdown document with broken links annotated with HTML comment."
    )
    # positional arguments
    parser.add_argument("input_file", help="Path to input markdown file.")

    # named parameters
    parser.add_argument(
        "-o",
        "--output_file",
        help="Path to output markdown file name.",
        type=str,
        default=None,
    )

    parser.add_argument(
        "-c",
        "--comment_out",
        help="Comment out broken links instead of annotating them with the comment.",
        type=str,
        default=None,
    )

    # switch
    parser.add_argument(
        "-q",
        "--quiet",
        action="store_true",
        default=False,
        help="quiet mode - do not print info on each link",
    )

    # switch
    parser.add_argument(
        "-s",
        "--summary",
        action="store_true",
        default=False,
        help="Display summary of working and broken links",
    )

    args = parser.parse_args()

    if args.output_file is None:
        # add _commented to the input file name
        output_file = input_file.replace(".md", "_commented.md")

    num_working_links, num_broken_links = check_markdown_file(
        input_file=args.input_file,
        output_file=args.output_file,
        comment_out=args.comment_out,
        quiet=args.quiet,
    )

    if args.summary:
        print(f"Working links: {num_working_links}")
        print(f"Broken links: {num_broken_links}")
