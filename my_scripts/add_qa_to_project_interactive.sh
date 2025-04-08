#!/usr/bin/env bash
#
# Name: add_qa_to_project_interactive.sh
# Description: Interactively adds quality assurance tools to a Python/JavaScript project
#
# This script prompts before adding each QA configuration file to the project:
# - ruff.toml
# - pre-commit hooks configuration
# - flake8 configuration
# - README template
# - gitignore for Python
# - LICENSE (MIT)
# - editorconfig
# - bandit security scanner configuration
# - mypy type checker configuration
# - tox configuration
# - pytest configuration
# - cliff.toml
#
# Usage: ./add_qa_to_project_interactive.sh [--help]
#
# Author: Your Name <your.email@example.com>
# Created: $(date +%Y-%m-%d)
# License: MIT
#
# Dependencies:
# - curl
# - pip
# - pre-commit
#
# Exit codes:
#   0 - Success
#   1 - Required dependency missing
#
# shellcheck disable=SC2059  # Allow printf without formatting

set -euo pipefail  # Exit on error, undefined var, pipe failure

# Function to display help message
show_help() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo
    echo "Interactively adds quality assurance tools to a Python/JavaScript project."
    echo
    echo "Options:"
    echo "  --help    Display this help message and exit"
    echo
    echo "This script will prompt before downloading each configuration file."
    echo "Files that will be offered for download:"
    echo "  - ruff.toml"
    echo "  - .pre-commit-config.yaml"
    echo "  - .flake8"
    echo "  - README.md template"
    echo "  - .gitignore for Python"
    echo "  - LICENSE (MIT)"
    echo "  - .editorconfig"
    echo "  - .bandit"
    echo "  - mypy.ini"
    echo "  - tox.ini"
    echo "  - pytest.ini"
    echo "  - cliff.toml"
    echo
    echo "You can quit at any time by responding with 'q'."
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

# Function to download a file with confirmation
download_file() {
    local url=$1
    local filename=$2

    if [ -f "$filename" ]; then
        read -p "File $filename already exists. Overwrite? [y/n/q] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            curl -sL "$url" -o "$filename"
            echo " -- $filename downloaded"
        elif [[ $REPLY =~ ^[Qq]$ ]]; then
            echo "Exiting..."
            exit 0
        fi
    else
        read -p "Do you want to add $filename? [y/n/q] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            curl -sL "$url" -o "$filename"
            echo " -- $filename downloaded"
        elif [[ $REPLY =~ ^[Qq]$ ]]; then
            echo "Exiting..."
            exit 0
        fi
    fi
}

# Function to install and update pre-commit
install_pre_commit() {
    read -p "Do you want to install pre-commit package and autoupdate? [y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        pip install pre-commit
        pre-commit autoupdate
    fi
}

# Check for required dependencies
for cmd in curl pip; do
  if ! command -v "$cmd" &> /dev/null; then
    printf "Error: %s is required but not installed.\n" "$cmd" >&2
    exit 1
  fi
done

# Main execution
# Most frequently used
download_file "https://gist.github.com/izikeros/8cbc53d9fd6c40b38b52bebd718fce37/raw" "./ruff.toml"

# Pre-commit install
install_pre_commit

# Download required files
download_file "https://gist.github.com/izikeros/937b05e81b5dca81d3daf309ea6bad20/raw" "./.pre-commit-config.yaml"
download_file "https://gist.github.com/izikeros/c938c49f5ad38dcc74a5671e85f694e7/raw" "./.flake8"
download_file "https://gist.github.com/izikeros/87b544d1ba644cc89dccca04fc87d65d/raw" "./README.md"
download_file "https://raw.githubusercontent.com/github/gitignore/main/Python.gitignore" "./.gitignore"
echo "(MIT license)"
download_file "https://raw.githubusercontent.com/licenses/license-templates/master/templates/mit.txt" "LICENSE"
download_file "https://gist.github.com/izikeros/d4359ff65052fc21df778a7f7373f0e2/raw" ".editorconfig"
download_file "https://gist.github.com/izikeros/4c38eb8ee022eda256a7880ddbd6f834/raw" "./.bandit"
download_file "https://gist.github.com/izikeros/946d65c15190b7cf48590f629119ab60/raw" "./mypy.ini"
download_file "https://gist.github.com/izikeros/1a2243e083d083c2a4f97cf9c19648d9/raw" "./tox.ini"
download_file "https://gist.github.com/izikeros/4c79e2f82b68083b8a0b23badc36204d/raw" "./pytest.ini"
download_file "https://gist.github.com/izikeros/b150d96360ee7bda5e0c7a750e90561d/raw/" "./cliff.toml"
# Uncomment the next line if you need to download requirements-dev.txt
# download_file "https://gist.github.com/izikeros/beac1ca8de132ad527ab27e32a950a11/raw" "./requirements-dev.txt"
