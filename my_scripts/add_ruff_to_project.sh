#!/usr/bin/env bash
#
# Name: add_ruff_to_project.sh
# Description: Adds Ruff linter configuration to a Python project
#
# This script downloads and configures the Ruff linter configuration file (ruff.toml)
# for Python projects to enforce consistent code style and quality.
#
# Usage: ./add_ruff_to_project.sh [--help]
#
# Author: Your Name <your.email@example.com>
# Created: $(date +%Y-%m-%d)
# License: MIT
#
# Dependencies:
# - curl
#
# Exit codes:
#   0 - Success
#   1 - Required dependency missing
#
# shellcheck disable=SC2086  # Allow word splitting in curl command

set -euo pipefail  # Exit on error, undefined var, pipe failure

# Function to display help message
show_help() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo
    echo "Adds Ruff linter configuration to a Python project."
    echo
    echo "Options:"
    echo "  --help    Display this help message and exit"
    echo
    echo "This script downloads the ruff.toml configuration file."
}

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            show_help
            exit 1
            ;;
    esac
done

# Check for required dependencies
if ! command -v curl &> /dev/null; then
    echo "Error: curl is required but not installed." >&2
    exit 1
fi

# function to download a file based on user input
function download_file() {
    local url=$1
    local filename=$2
    curl -sL "$url" -o "$filename"
    echo " -- $filename downloaded successfully"
}

download_file https://gist.github.com/izikeros/8cbc53d9fd6c40b38b52bebd718fce37/raw ./ruff.toml
