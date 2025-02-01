#!/usr/bin/env python3
import json
import os
from datetime import datetime

# Path to Brave's Bookmarks file
bookmarks_path = os.path.expanduser(
    "~/Library/Application Support/BraveSoftware/Brave-Browser/Default/Bookmarks"
)

# Set up the output directory
output_dir = os.path.expanduser("~/data")
os.makedirs(output_dir, exist_ok=True)

# Generate the output filename with timestamp
timestamp = datetime.now().strftime("%y%m%d")
output_file = f"brave_bookmarks_{timestamp}.json"
output_path = os.path.join(output_dir, output_file)

# Read the Bookmarks file
with open(bookmarks_path, "r", encoding="utf-8") as f:
    bookmarks_data = json.load(f)


# Function to extract bookmarks recursively
def extract_bookmarks(node):
    bookmarks = []
    if node["type"] == "url":
        bookmarks.append(
            {"name": node["name"], "url": node["url"], "date_added": node["date_added"]}
        )
    elif "children" in node:
        for child in node["children"]:
            bookmarks.extend(extract_bookmarks(child))
    return bookmarks


# Extract all bookmarks
all_bookmarks = []
for root in bookmarks_data["roots"].values():
    all_bookmarks.extend(extract_bookmarks(root))

# Write to JSON file
with open(output_path, "w", encoding="utf-8") as f:
    json.dump(all_bookmarks, f, indent=2, ensure_ascii=False)

print(f"Bookmarks saved to: {output_path}")
print(f"{len(all_bookmarks)} bookmarks saved.")
