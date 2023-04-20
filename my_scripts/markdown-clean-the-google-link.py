#!/usr/bin/env python3
"""Clean the all the google search links in a markdown file.
if no output file is specified, the input file is overwritten.
"""

import argparse
import re


def clean_google_search_link(link):
    parts = link.split("?")
    base = parts[0]
    query_string = parts[1]
    queries = query_string.split("&")
    cleaned_queries = []
    for query in queries:
        if "q=" in query:
            cleaned_queries.append(query)
    return base + "?" + "&".join(cleaned_queries)


def clean_file(input_file, output_file=None, quiet=False):
    num_google_links = 0
    num_lines = 0
    if output_file is None:
        output_file = input_file
    # Read the input markdown file
    with open(input_file, "r") as f:
        lines = f.readlines()

    # Process lines and write the output markdown file
    with open(output_file, "w") as f:
        for line in lines:
            if match := re.search(r"\[.*]\((.*)\)", line):
                link = match[1]
                if "google.com/search" in link:
                    num_google_links += 1
                    print(link)
                    clean_link = clean_google_search_link(link)
                    if not quiet:
                        print(f"Cleaned link: {clean_link}")
                else:
                    clean_link = link
                # replace the link with the cleaned link in the line string
                line = line.replace(link, clean_link)
            f.write(line)
    print(f"Number of google links: {num_google_links}")
    print(f"Number of lines: {num_lines}")


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description="Purpose of the script")

    parser.add_argument("input", help="input file")
    parser.add_argument(
        "-o",
        "--output_file",
        help="Path to output markdown file name.",
        type=str,
        default=None,
    )

    # switch
    parser.add_argument(
        "--quiet", action="store_true", default=False, help="quiet mode"
    )
    args = parser.parse_args()

    clean_file(args.input, args.output_file, args.quiet)
