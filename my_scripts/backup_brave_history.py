#!/usr/bin/env python3
import argparse
import json
import os
import sqlite3
import sys
import time
from datetime import datetime, timedelta


def convert_chrome_time(chrome_time):
    """Convert Chrome time format to datetime."""
    return datetime(1601, 1, 1) + timedelta(microseconds=chrome_time)


def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Backup Brave browser history to a JSON file.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                    # Backup history with default settings
  %(prog)s --output-dir ~/backups  # Backup to custom directory
  
Output:
  The script saves browser history to a JSON file named 'brave_history_YYMMDD.json'
  in the specified output directory (default: ~/data).
  
Requirements:
  - Brave browser must be closed during backup
  - The script needs read access to Brave's profile directory
        """
    )
    
    parser.add_argument(
        "--output-dir",
        default="~/data",
        help="Directory to save the backup file (default: ~/data)"
    )
    
    parser.add_argument(
        "--version",
        action="version",
        version="%(prog)s 1.0"
    )
    
    return parser.parse_args()


# Path to Brave's History file
history_path = os.path.expanduser(
    "~/Library/Application Support/BraveSoftware/Brave-Browser/Default/History"
)


def main():
    """Main function to execute the backup process."""
    # Parse command line arguments
    args = parse_arguments()
    
    # Set up the output directory
    output_dir = os.path.expanduser(args.output_dir)
    os.makedirs(output_dir, exist_ok=True)

    # Generate the output filename with timestamp
    timestamp = datetime.now().strftime("%y%m%d")
    output_file = f"brave_history_{timestamp}.json"
    output_path = os.path.join(output_dir, output_file)

    try:
        # Connect to the database
        conn = connect_to_db()
        cursor = conn.cursor()

        # Query the database
        cursor.execute(
            "SELECT url, title, last_visit_time FROM urls ORDER BY last_visit_time DESC"
        )

        # Fetch the results
        results = cursor.fetchall()

        # Convert to list of dictionaries with human-readable timestamp
        history = [
            {
                "url": row[0],
                "title": row[1],
                "last_visit_time": convert_chrome_time(row[2]).isoformat(),
            }
            for row in results
        ]

        # Write to JSON file
        with open(output_path, "w") as f:
            json.dump(history, f, indent=2)

        print(f"History saved to: {output_path}")
        print(f"{len(history)} records saved.")

    except Exception as e:
        print(f"An error occurred: {e!s}")
        print("\nHelpful hint:")
        print("1. Make sure Brave browser is completely closed.")
        print("2. If the issue persists, restart your computer and try again.")
        print(
            "3. If you're using any sync or backup software, temporarily disable it and retry."
        )

    finally:
        if "conn" in locals():
            conn.close()


# Function to attempt database connection with retry
def connect_to_db(max_attempts=5, delay=2):
    for attempt in range(max_attempts):
        try:
            return sqlite3.connect(history_path)
        except sqlite3.OperationalError as e:
            if "database is locked" in str(e):
                if attempt < max_attempts - 1:
                    print(
                        f"Database is locked. Retrying in {delay} seconds... (Attempt {attempt + 1}/{max_attempts})"
                    )
                    time.sleep(delay)
                else:
                    raise Exception(
                        "Failed to access the database after multiple attempts. Please ensure Brave browser is closed and try again."
                    ) from e
            else:
                raise


if __name__ == "__main__":
    main()
