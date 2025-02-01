#!/usr/bin/env python3

import argparse
import csv
import os


def parse_event_dirs(root_dir, output_file, quiet):
    event_list = []

    for year_dir in os.listdir(root_dir):
        if len(year_dir) == 4 and year_dir.isdigit():
            if not quiet:
                print(f"processing {year_dir}")
            year_path = os.path.join(root_dir, year_dir)
            for event_dir in os.listdir(year_path):
                if event_dir.startswith("["):
                    date_end = event_dir.index("]") + 1
                    event_date = event_dir[1 : date_end - 1]
                    event_date = event_dir[1 : date_end - 1].replace("_", "-")
                    event_name = event_dir[date_end + 1 :].strip()
                    event_list.append((event_date, event_name))

    with open(output_file, "w", newline="") as csvfile:
        csv_writer = csv.writer(csvfile, delimiter=";")
        csv_writer.writerow(["eventDate", "eventName"])
        csv_writer.writerows(event_list)


def main():
    parser = argparse.ArgumentParser(
        description="Generate a CSV list of event names and dates."
    )
    parser.add_argument(
        "root_dir", help="Parent directory containing year and event folders"
    )
    parser.add_argument(
        "-o", "--output", default="photo_events.csv", help="Output CSV file name"
    )
    parser.add_argument("-s", "--summary", action="store_true", help="Display summary")
    parser.add_argument(
        "-q",
        "--quiet",
        action="store_true",
        help="Quiet mode, suppress progress and summary messages",
    )
    args = parser.parse_args()

    if os.path.exists(args.output):
        if not args.quiet:
            choice = input(
                f"Output file '{args.output}' already exists. Overwrite? (y/n): "
            )
            if choice.lower() != "y":
                print("Exiting.")
                return

    parse_event_dirs(args.root_dir, args.output, args.quiet)

    if not args.quiet:
        print("Event list generated successfully.")

    if args.summary:
        event_count = sum(1 for line in open(args.output)) - 1
        year_count = sum(
            1
            for entry in os.listdir(args.root_dir)
            if len(entry) == 4 and entry.isdigit()
        )
        summary = f"Results saved in '{args.output}'. Found {event_count} events in {year_count} years."
        if not args.quiet:
            print(summary)


if __name__ == "__main__":
    main()
