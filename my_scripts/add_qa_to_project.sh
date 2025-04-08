#!/usr/bin/env bash
#
# Name: add_qa_to_project.sh
# Description: Sets up code quality tools for Python projects
#
# This script downloads and configures common quality assurance tools:
# - pre-commit hooks configuration
# - flake8 configuration
# - bandit security scanner configuration
# - mypy type checker configuration
#
# Usage: ./add_qa_to_project.sh
#
# Author: Krystian Safjan <ksafjan@gmail.com>
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

# Check for required dependencies
for cmd in curl pip; do
  if ! command -v "$cmd" &> /dev/null; then
    printf "Error: %s is required but not installed.\n" "$cmd" >&2
    exit 1
  fi
done

# download pre-commit hooks configuration if file does not exist
if [ ! -f .pre-commit-config ]; then
  curl -L https://gist.githubusercontent.com/izikeros/937b05e81b5dca81d3daf309ea6bad20/raw -o .pre-commit-config.yaml
  echo " -- .pre-commit-config.yaml downloaded"
  echo "(!) edit zimport style to match style for flake8-import-order defined in .flake8 file"
else
  echo "File .pre-commit-config already exists. Delete it if you want to download a new one."
fi

# install or upgrade pre-commit
pip install --upgrade pre-commit

pre-commit autoupdate

# download .flake8 config
if [ ! -f .flake8 ]; then
  curl -L https://gist.github.com/izikeros/c938c49f5ad38dcc74a5671e85f694e7/raw -o .flake8
  echo " -- .flake8 config downloaded"
  echo "(!) edit flake8-import-order style to match style for zimport defined in .pre-commit-config.yaml"
else
  echo "File .flake8 already exists. Delete it if you want to download a new one."
fi

# download .bandit
if [ ! -f .bandit ]; then
  curl -L https://gist.github.com/izikeros/4c38eb8ee022eda256a7880ddbd6f834/raw -o .bandit
  echo "-- .bandit file downloaded"
  echo "(!) Edit targets in .bandit file to match your project"
else
  echo "File .bandit already exists. Delete it if you want to download a new one."
fi

# download mypy.ini
if [ ! -f mypy.ini ]; then
  curl -L https://gist.github.com/izikeros/946d65c15190b7cf48590f629119ab60/raw -o mypy.ini
  echo " -- mypy.ini downloaded"
  echo "(!) edit mypy.ini to adjust ignored libraries to match your project"
else
  echo "File mypy.ini already exists. Delete it if you want to download a new one."
fi
