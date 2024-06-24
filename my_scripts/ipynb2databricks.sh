#!/bin/bash
# Convert Jupyter Notebook to Databricks script and vice versa
# Usage: ./ipynb2databricks.sh [file_path]
#
# Source: https://github.com/mwouts/jupytext/issues/926#issuecomment-1602366106
# Author: Martin Gärdestad (mgardestad) <martin@gardestad.se>

# Read the file path argument
file_path="$1"

# Extract the file extension
file_extension="${file_path##*.}"

# Extract the file name
file_name="${file_path%.*}"

# Perform actions based on the file extension
case "$file_extension" in
  "ipynb")
    # Transform .ipynb to Python file with percent format
    transformed=$(jupytext --to py:percent --update-metadata '{"jupytext": {"notebook_metadata_filter":"-all"}}' < "$file_path" | awk '{gsub("# %%", "# COMMAND ----------")}1')

    # Replace the first line with "# Databricks notebook source"
    transformed=$(awk 'NR==1 {gsub("# COMMAND ----------", "# Databricks notebook source")}1' <<< "$transformed")

    # Output the result
    echo "$transformed" > "$file_name.py"
    ;;
  "py")
    # Replace the first line with "# COMMAND ----------"
    transformed=$(awk 'NR==1 {gsub("# Databricks notebook source", "# COMMAND ----------")}1' "$file_path")

    # Replace all "# COMMAND ----------" with "# %%"
    transformed=$(echo "$transformed" | awk '{gsub("# COMMAND ----------", "# %%")}1')

    # Transform .py to Jupyter Notebook
    transformed=$(jupytext --set-kernel dbconnect --to ipynb --update-metadata '{"jupytext": {"notebook_metadata_filter":"-all"}}' <<< "$transformed")

    # Output the result
    echo "$transformed" > "$file_name.ipynb"
    ;;
  *)
    # Default case for unsupported file types
    echo "Unsupported file type: $file_extension"
    exit 1
    ;;
esac
