#!/usr/bin/env python3
"""Script do pinning of unpinned packages in requirements.txt file.

Results are written to requirements_pinned.txt file and displayed on stdout.
"""
import importlib.metadata
import re


def get_installed_packages():
    return {
        dist.metadata["Name"]: dist.version
        for dist in importlib.metadata.distributions()
    }


def enrich_requirements(filename):
    installed_packages = get_installed_packages()
    installed_packages_lower = {k.lower(): v for k, v in installed_packages.items()}

    enriched_requirements = []
    with open(filename) as f:
        for line in f:
            # non-strict splitting by '#'
            parts = line.split("#", 1)
            # package part might contain version or comparison operators, take care of it
            package_parts = re.split(r"(==|>=|<=|<|>)", parts[0])
            package = package_parts[0].strip()
            # check if package already has a pinned version
            # if not, add version from installed packages
            if package.lower() in installed_packages_lower:  # and '==' not in parts[0]
                # if none of the version comparison operators are present add pinned version
                if not any(op in parts[0] for op in ["==", ">=", "<=", "<", ">"]):
                    parts[0] = f"{package}=={installed_packages_lower[package.lower()]}"
            # put the line back together
            enriched_line = "  #".join(parts)
            enriched_requirements.append(enriched_line.strip() + "\n")
    return enriched_requirements


def write_enriched_requirements(filename, enriched_requirements):
    with open(filename, "w") as f:
        for line in enriched_requirements:
            # ensure each package is in separate line
            f.write(line.strip() + "\n")

    print("".join(enriched_requirements))


requirement_file = "requirements.txt"
requirement_out_file = "requirements_pinned.txt"
requirements = enrich_requirements(requirement_file)
write_enriched_requirements(requirement_out_file, requirements)
