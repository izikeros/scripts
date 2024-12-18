#!/usr/bin/env python3
import os
import sys
import argparse
import subprocess
import json
from pathlib import Path
from typing import Optional, Dict, List

def find_python_venv(project_path: Path) -> Optional[Dict[str, str]]:
    """
    Find and analyze Python virtual environment in a project directory.
    
    Args:
        project_path (Path): Path to the project directory
    
    Returns:
        Optional[Dict[str, str]]: Dictionary with venv details or None
    """
    # Check common virtual environment locations
    venv_paths = [
        project_path / '.venv',
        project_path / 'venv',
        project_path / 'env'
    ]
    
    for venv_path in venv_paths:
        if venv_path.exists():
            # Try to find Python interpreter
            possible_interpreters = [
                venv_path / 'bin' / 'python',  # Unix-like systems
                venv_path / 'Scripts' / 'python.exe',  # Windows
            ]
            
            for interpreter in possible_interpreters:
                if interpreter.exists():
                    try:
                        # Get Python version
                        version_output = subprocess.check_output(
                            [str(interpreter), '--version'], 
                            text=True
                        ).strip()
                        
                        return {
                            'python_version': version_output.split()[1],
                            'interpreter_path': str(interpreter)
                        }
                    except Exception:
                        continue
    
    return None

def scan_projects(projects_dir: Path) -> List[Dict[str, str]]:
    """
    Scan projects directory for Python virtual environments.
    
    Args:
        projects_dir (Path): Directory containing project folders
    
    Returns:
        List[Dict[str, str]]: List of project venv details
    """
    results = []
    
    for project_folder in projects_dir.iterdir():
        if project_folder.is_dir():
            venv_info = find_python_venv(project_folder)
            
            if venv_info:
                results.append({
                    'project_name': project_folder.name,
                    **venv_info
                })
    
    return results

def main():
    # Set up argument parsing
    parser = argparse.ArgumentParser(
        description='Find Python virtual environments in project directories'
    )
    parser.add_argument(
        'projects_dir', 
        type=Path, 
        help='Path to projects directory'
    )
    parser.add_argument(
        '-f', '--format', 
        choices=['table', 'json'], 
        default='table', 
        help='Output format (default: table)'
    )
    
    # Parse arguments
    args = parser.parse_args()
    
    # Validate input directory
    if not args.projects_dir.is_dir():
        print(f"Error: {args.projects_dir} is not a valid directory", file=sys.stderr)
        sys.exit(1)
    
    # Scan projects
    projects_with_venv = scan_projects(args.projects_dir)
    
    # Output results
    if args.format == 'json':
        print(json.dumps(projects_with_venv, indent=2))
    else:
        # Table format
        print(f"{'Project Name':<20} {'Python Version':<15} {'Interpreter Path'}")
        print('-' * 70)
        for project in projects_with_venv:
            print(
                f"{project['project_name']:<20} "
                f"{project['python_version']:<15} "
                f"{project['interpreter_path']}"
            )

if __name__ == '__main__':
    main()