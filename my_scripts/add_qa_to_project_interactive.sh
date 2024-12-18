#!/usr/bin/env bash
# This script adds QA tools to a project, asking one by one if you want to add them.
# It is interactive and asks for confirmation before adding each file.

# Exit immediately if a command exits with a non-zero status.
set -e

# Function to download a file based on user input
download_file() {
    local url=$1
    local filename=$2
    read -p "Do you want to add $filename? [y/n/q] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        curl -sL "$url" -o "$filename"
    elif [[ $REPLY =~ ^[Qq]$ ]]; then
        echo "Exiting..."
        exit 0
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
