#!/usr/bin/env python3
"""
Python Virtual Environment Scanner and Analyzer

Purpose:
    This script provides a comprehensive tool for discovering and analyzing Python
    virtual environments across multiple projects in a directory. It supports
    various virtual environment management tools and platforms.

Key Features:
    1. Multi-tool Virtual Environment Detection
    2. Cross-platform Support (Unix, Windows)
    3. Flexible Output Formats (Table and JSON)
    4. Comprehensive Virtual Environment Location Scanning
    5. Detection of virtual environment management tools (e.g., Poetry, Pipenv, PDM)
    6. Graceful handling of errors during interpreter or virtual environment detection

Detailed Functionality:

Virtual Environment Discovery:
    The script scans a specified directory for Python projects and attempts to
    locate their associated virtual environments through multiple strategies:

    a) Local Directory Checks:
       - Searches for virtual environments in common local directories:
         * `.venv/`
         * `venv/`
         * `env/`
       - If none of these directories exist, the project is scanned for tool-specific
         configurations or falls back to system Python as a last resort.

    b) Tool-Specific Virtual Environment Detection:
       Supports multiple virtual environment management tools:
       - Poetry:
         * Checks `pyproject.toml` and `poetry.lock`
         * Scans Poetry's default virtual environment location
           (typically `~/.cache/pypoetry/virtualenvs/`)

       - Pipenv:
         * Checks `Pipfile` and `Pipfile.lock`
         * Scans Pipenv's default virtual environment location
           (typically `~/.local/share/virtualenvs/`)

       - PDM:
         * Checks `pyproject.toml`

       - Conda:
         * Checks `environment.yml`

    c) Pure Venv Detection:
       - Detects virtual environments created without a specific management tool
         if `.venv/`, `venv/`, or `env/` directories are present.

    d) Fallback Mechanism:
       - If no specific virtual environment is found, the script attempts to
         detect the system Python as a fallback.

Interpreter Detection:
    For each potential virtual environment, the script:
    1. Identifies Python interpreter locations
    2. Extracts Python version
    3. Supports multiple interpreter paths:
       - Unix: `bin/python`, `bin/python3`
       - Windows: `Scripts/python.exe`

Output Modes:
    1. Table Format:
       - Displays project-wise virtual environment details
       - Columns include:
         * Project Name
         * Python Version
         * Management Tools
         * Interpreter Path
       - Dynamically adjusts column widths for readability

    2. JSON Format:
       - Provides machine-readable output
       - Includes comprehensive virtual environment metadata

Command-Line Usage:
    ```
    python venv_scanner.py /path/to/projects/directory [-f {table,json}]
    ```

    Options:
    - `projects_dir`: Mandatory argument specifying the directory to scan
    - `-f, --format`: Optional output format (default: table)
      * 'table': Human-readable tabular format
      * 'json': Machine-readable JSON format

Error Handling:
    - Validates input directory
    - Gracefully handles missing or inaccessible virtual environments
    - Handles Python interpreter detection failures (e.g., subprocess errors) gracefully
    - Provides clear error messages for unsupported directories or invalid inputs

Platform Compatibility:
    - Works on Unix-like systems (Linux, macOS)
    - Supports Windows environments
    - Adapts interpreter detection based on operating system

Dependencies:
    - Python 3.7+
    - Standard library modules: os, sys, argparse, subprocess, json, typing
    - pathlib for path manipulations
    - shutil for system path lookups

Example Scenarios:
    1. Scanning a directory with multiple Python projects
    2. Identifying Python versions across different projects
    3. Discovering virtual environment management tools in use
    4. Generating an inventory of project Python environments

Limitations:
    - Requires read access to project and virtual environment directories
    - May not detect highly customized or non-standard virtual environments
"""

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path


def find_tool_venv_path(project_path: Path, tool: str) -> Path | None:
    """
    Find virtual environment path for specific tools
    """
    home_dir = Path.home()
    if tool == "poetry":
        poetry_venv_base = home_dir / ".cache" / "pypoetry" / "virtualenvs"
        if poetry_venv_base.exists():
            project_name = project_path.name
            for venv_dir in poetry_venv_base.glob(f"{project_name}-*"):
                if venv_dir.is_dir():
                    return venv_dir

    elif tool == "pipenv":
        pipenv_venv_base = home_dir / ".local" / "share" / "virtualenvs"
        if pipenv_venv_base.exists():
            project_name = project_path.name
            for venv_dir in pipenv_venv_base.glob(f"{project_name}-*"):
                if venv_dir.is_dir():
                    return venv_dir

    return None


def find_python_interpreter(venv_path: Path) -> dict[str, str] | None:
    """
    Find Python interpreter in a virtual environment
    """
    possible_interpreters = [
        venv_path / "bin" / "python",
        venv_path / "Scripts" / "python.exe",
        venv_path / "bin" / "python3",
    ]
    for interpreter in possible_interpreters:
        if interpreter.exists():
            try:
                version_output = subprocess.check_output(
                    [str(interpreter), "--version"], text=True, stderr=subprocess.STDOUT
                ).strip()
                return {
                    "python_version": version_output.split()[1],
                    "interpreter_path": str(interpreter),
                }
            except subprocess.CalledProcessError as e:
                print(f"Error checking Python version: {e}", file=sys.stderr)
    return None


def find_python_venv(project_path: Path) -> dict[str, str] | None:
    """
    Find Python virtual environment for a project
    """
    local_venv_paths = [
        project_path / ".venv",
        project_path / "venv",
        project_path / "env",
    ]
    for local_venv in local_venv_paths:
        if local_venv.exists():
            venv_info = find_python_interpreter(local_venv)
            if venv_info:
                return venv_info

    tools_to_check = ["poetry", "pipenv", "pdm"]
    for tool in tools_to_check:
        tool_venv = find_tool_venv_path(project_path, tool)
        if tool_venv:
            venv_info = find_python_interpreter(tool_venv)
            if venv_info:
                return {**venv_info, "venv_tool": tool}

    python_executable = shutil.which("python")
    if python_executable:
        try:
            version_output = subprocess.check_output(
                [python_executable, "--version"], text=True
            ).strip()
            return {
                "python_version": version_output.split()[1],
                "interpreter_path": python_executable,
                "venv_tool": "system python",
            }
        except subprocess.CalledProcessError:
            pass

    return None


def find_venv_management_tool(project_path: Path) -> list[str]:
    """
    Detect virtual environment management tools
    """
    detection_patterns = {
        "poetry": ["pyproject.toml", "poetry.lock"],
        "pipenv": ["Pipfile", "Pipfile.lock"],
        "pdm": ["pyproject.toml", "pdm.lock"],
        "conda": ["environment.yml"],
    }
    detected_tools = []
    for tool, files in detection_patterns.items():
        if all((project_path / file).exists() for file in files):
            detected_tools.append(tool)
    return detected_tools if detected_tools else ["unknown"]


def scan_projects(projects_dir: Path) -> list[dict[str, str]]:
    """
    Scan projects directory for Python virtual environments
    """
    results = []
    for project_folder in projects_dir.iterdir():
        if project_folder.is_dir():
            venv_info = find_python_venv(project_folder)
            if venv_info:
                results.append(
                    {
                        "project_name": project_folder.name,
                        **venv_info,
                        "management_tools": find_venv_management_tool(project_folder),
                    }
                )
    return results


def main():
    parser = argparse.ArgumentParser(
        description="Find Python virtual environments in project directories"
    )
    parser.add_argument("projects_dir", type=Path, help="Path to projects directory")
    parser.add_argument(
        "-f",
        "--format",
        choices=["table", "json"],
        default="table",
        help="Output format (default: table)",
    )
    args = parser.parse_args()

    if not args.projects_dir.is_dir():
        print(f"Error: {args.projects_dir} is not a valid directory", file=sys.stderr)
        sys.exit(1)

    projects_with_venv = scan_projects(args.projects_dir)
    if args.format == "json":
        print(json.dumps(projects_with_venv, indent=2))
    else:
        column_widths = {
            "project_name": max(
                len("Project Name"),
                *(len(p["project_name"]) for p in projects_with_venv),
            ),
            "python_version": max(
                len("Python Version"),
                *(len(p["python_version"]) for p in projects_with_venv),
            ),
            "management_tools": max(
                len("Management Tools"),
                *(len(", ".join(p["management_tools"])) for p in projects_with_venv),
            ),
            "interpreter_path": max(
                len("Interpreter Path"),
                *(len(p["interpreter_path"]) for p in projects_with_venv),
            ),
        }
        header_format = f"{{:<{column_widths['project_name']}}} {{:<{column_widths['python_version']}}} {{:<{column_widths['management_tools']}}} {{:<{column_widths['interpreter_path']}}}"
        print(
            header_format.format(
                "Project Name", "Python Version", "Management Tools", "Interpreter Path"
            )
        )
        print("-" * sum(column_widths.values()))
        for project in projects_with_venv:
            print(
                header_format.format(
                    project["project_name"],
                    project["python_version"],
                    ", ".join(project["management_tools"]),
                    project["interpreter_path"],
                )
            )
        print(f"\nTotal projects analyzed: {len(projects_with_venv)}")


if __name__ == "__main__":
    main()
