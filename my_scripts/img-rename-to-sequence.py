#!/bin/python3

import os

counter = 0
extensions = [".jpg", ".jpeg", ".png", ".gif", ".tiff", ".heic", ".heif"]

for filename in os.listdir("."):
    if filename.lower().endswith(tuple(extensions)) and os.path.isfile(filename):
        file_parts = os.path.splitext(filename)
        newname = f"img_{counter:03d}{file_parts[1]}"
        os.rename(filename, newname)
        counter += 1

