#!/usr/bin/env bash
# move-venv-pdm.sh
# Move .venv directory to the specified virtualenvs directory
# and update .pdm-python file with the new virtualenv path
#
# usage:
# ./move-venv-pdm.sh
#
set -Eeuo pipefail

# Default virtualenvs directory
DEFAULT_VENV_DIR="$HOME/.virtualenvs"

# Function to move .venv directory to the specified virtualenvs directory
function move_venv() {
  local default_venv_dir="$1"
  local venv_dir=".venv"
  local current_dir_name=$(basename "$PWD")
  local target_dir="$default_venv_dir/$current_dir_name"

  if [[ ! -d "$default_venv_dir" ]]; then
    echo "Error: Virtualenvs directory '$default_venv_dir' does not exist. Creating it..."
    mkdir -p "$default_venv_dir"
  fi

  if [[ -d "$target_dir" ]]; then
    echo "Error: Virtualenv directory '$target_dir' already exists in '$default_venv_dir'."
    exit 1
  fi

  mv "$venv_dir" "$target_dir/"
  echo "Moved $venv_dir to $target_dir."
}

# Function to update .pdm-python file with the new virtualenv path
function update_pdm_python() {
  local pdm_python_file=".pdm-python"
  local current_dir_name=$(basename "$PWD")
  local target_dir="$DEFAULT_VENV_DIR/$current_dir_name"

  if [[ ! -f "$pdm_python_file" ]]; then
    echo "Error: $pdm_python_file not found in the current directory."
    exit 1
  fi

  local current_dir_name=$(basename "$PWD")
  sed -i -e "s|$PWD/.venv/bin/python|$target_dir/bin/python|" "$pdm_python_file"
  echo "Updated $pdm_python_file with the new virtualenv path:"
  # display file content
  echo "-------------------------------------"
  cat "$pdm_python_file"
  echo "-------------------------------------"
}

# Move .venv directory to the specified virtualenvs directory
move_venv "$DEFAULT_VENV_DIR"

# Update .pdm-python file with the new virtualenv path
update_pdm_python "$DEFAULT_VENV_DIR"

echo "Actions completed successfully!"
