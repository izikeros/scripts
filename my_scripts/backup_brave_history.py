#!/usr/bin/env python3

import sqlite3
import json
import os
from datetime import datetime, timedelta

def convert_chrome_time(chrome_time):
    """Convert Chrome time format to datetime."""
    return datetime(1601, 1, 1) + timedelta(microseconds=chrome_time)

# Path to Brave's History file
history_path = os.path.expanduser('~/Library/Application Support/BraveSoftware/Brave-Browser/Default/History')

# Set up the output directory
output_dir = os.path.expanduser('~/data')
os.makedirs(output_dir, exist_ok=True)

# Generate the output filename with timestamp
timestamp = datetime.now().strftime("%y%m%d")
output_file = f"brave_history_{timestamp}.json"
output_path = os.path.join(output_dir, output_file)

# Connect to the database
conn = sqlite3.connect(history_path)
cursor = conn.cursor()

# Query the database
# cursor.execute("SELECT url, title, last_visit_time FROM urls ORDER BY last_visit_time DESC LIMIT 100")
cursor.execute("SELECT url, title, last_visit_time FROM urls ORDER BY last_visit_time DESC")

# Fetch the results
results = cursor.fetchall()

# Convert to list of dictionaries with human-readable timestamp
history = [
    {
        "url": row[0],
        "title": row[1],
        "last_visit_time": convert_chrome_time(row[2]).isoformat()
    } for row in results
]

# Write to JSON file
with open(output_path, 'w') as f:
    json.dump(history, f, indent=2)

conn.close()

print(f"History saved to: {output_path}")
print(f"{len(history)} records saved.")