#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "toml",
# ]
# ///
# Purpose
# -------
# update the minimum versions of dependencies in a `pyproject.toml` file based on a `requirements.txt` file.
#
# How it works:
# 1. Parses a `requirements.txt` file to get the latest versions of packages.
# 2. Reads a `pyproject.toml` file to find dependencies in the `[project]` and `[tool.poetry.dependencies]` sections.
# 3. Updates the versions in the `pyproject.toml` file to the latest versions from the `requirements.txt`.
#
# Usage:
# ```
# python update_project.py --file requirements.txt --dry-run
# ```



import argparse

try:
    import toml
except ImportError:
    print("Please install 'toml' package to use this script.")
    exit(1)


def parse_requirements(file_path):
    """Parse a requirements.txt file and return a dictionary of package versions."""
    versions = {}
    with open(file_path) as f:
        for line in f:
            line = line.strip()
            if "==" in line:
                package, version = line.split("==")
                versions[package.lower()] = version
    return versions


def update_dependencies(dependencies, updated_versions, section_name, use_pinned=False):
    """Update dependencies with new minimum versions, return updates made."""
    updates = {}

    # Choose the version prefix based on the pinning option
    version_prefix = "==" if use_pinned else ">="

    # Handle dictionary-style dependencies
    if isinstance(dependencies, dict):
        for package, version in dependencies.items():
            if isinstance(version, str) and package.lower() in updated_versions:
                new_version = f"{version_prefix}{updated_versions[package.lower()]}"
                if version != new_version:
                    updates[package] = (version, new_version)
                    dependencies[package] = new_version
    # Handle list-style dependencies
    elif isinstance(dependencies, list):
        for i, dep in enumerate(dependencies):
            # Parse package and version from string like "package>=1.0.0"
            if isinstance(dep, str) and (">=" in dep or "==" in dep):
                separator = ">=" if ">=" in dep else "=="
                parts = dep.split(separator)
                if len(parts) == 2:
                    package, _old_version = parts[0].strip(), parts[1].strip()
                    if package.lower() in updated_versions:
                        new_version = f"{package}{version_prefix}{updated_versions[package.lower()]}"
                        updates[package] = (dep, new_version)
                        dependencies[i] = new_version

    return updates


def main():
    """Main function to update pyproject.toml based on requirements.txt."""
    parser = argparse.ArgumentParser(
        description="Update minimum versions in pyproject.toml"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show changes without modifying pyproject.toml",
    )
    parser.add_argument(
        "--poetry", action="store_true", help="Update only poetry dependencies"
    )
    parser.add_argument(
        "--project", action="store_true", help="Update only project dependencies"
    )
    parser.add_argument(
        "--file",
        default="requirements.txt",
        help="Requirements file with latest versions",
    )
    parser.add_argument(
        "--pin",
        action="store_true",
        help="Use pinned versions (==version) instead of compatible versions (>=version)",
    )
    args = parser.parse_args()

    # Load latest versions from requirements file
    updated_versions = parse_requirements(args.file)

    # Load pyproject.toml
    with open("pyproject.toml") as f:
        data = toml.load(f)

    updates_made = {}

    # Update [project] dependencies (uv/pdm)
    if not args.poetry and "project" in data and "dependencies" in data["project"]:
        updates_made["project"] = update_dependencies(
            data["project"]["dependencies"], updated_versions, "project", args.pin
        )

    # Update [tool.poetry.dependencies]
    if (
        not args.project
        and "tool" in data
        and "poetry" in data["tool"]
        and "dependencies" in data["tool"]["poetry"]
    ):
        updates_made["poetry"] = update_dependencies(
            data["tool"]["poetry"]["dependencies"], updated_versions, "poetry", args.pin
        )

    # Dry run output
    if args.dry_run:
        if not updates_made:
            print("No updates available.")
        else:
            for section, updates in updates_made.items():
                if updates:
                    print(f"\n[{section}] updates:")
                    for pkg, (old, new) in updates.items():
                        print(f"  {pkg}: {old} → {new}")
        return

    # Save updated pyproject.toml
    if any(updates_made.values()):
        with open("pyproject.toml", "w") as f:
            toml.dump(data, f)
        print("Updated pyproject.toml successfully.")
    else:
        print("No changes made.")


if __name__ == "__main__":
    main()
